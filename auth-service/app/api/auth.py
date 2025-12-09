from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token, validate_password_strength
from app.models.user import User
from app.models.token import Token
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.token import TokenWithJWT

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_data: UserCreate, db: Session = Depends(get_db)) -> UserResponse:
    # check password
    is_valid, error_msg = validate_password_strength(user_data.password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )

    existing_user = db.query(User).filter(User.username == user_data.username).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already registered"
        )

    existing_email = db.query(User).filter(User.email == user_data.email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )

    hashed_password = hash_password(user_data.password)

    new_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password,
        is_active=True,
        is_superuser=False
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
    except IntegrityError:
        db.rollback()
        # Catch constraint violation
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username or email already registered"
        )

    return UserResponse.model_validate(new_user)


@router.post("/login", response_model=TokenWithJWT)
def login(login_data: UserLogin, request: Request, db: Session = Depends(get_db)) -> TokenWithJWT:
    user = db.query(User).filter(User.username == login_data.username).first()

    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User account is inactive")

    jwt_token, jti, expires_at = create_access_token(
        user_id=user.id,
        username=user.username,
        is_superuser=user.is_superuser
    )

    token_record = Token(user_id=user.id, jti=jti, expires_at=expires_at, is_revoked=False)
    db.add(token_record)
    db.commit()
    db.refresh(token_record)

    return TokenWithJWT(
        id=token_record.id,
        user_id=token_record.user_id,
        token_name=token_record.token_name,
        jti=token_record.jti,
        is_revoked=token_record.is_revoked,
        created_at=token_record.created_at,
        expires_at=token_record.expires_at,
        access_token=jwt_token,
        token_type="bearer"
    )
