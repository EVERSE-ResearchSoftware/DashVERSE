from datetime import datetime, timedelta, timezone
from typing import Optional
import jwt
from passlib.context import CryptContext
import uuid

from app.core.config import settings

pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,
    argon2__time_cost=3,
    argon2__parallelism=4,
)


def hash_password(password):
    return pwd_context.hash(password)


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def validate_password_strength(password: str) -> tuple[bool, Optional[str]]:
    min_length = settings.PASSWORD_MIN_LENGTH
    if len(password) < min_length:
        return False, f"Password must be at least {min_length} characters"
    return True, None


def create_access_token(
    user_id: int,
    username: str,
    is_superuser: bool = False,
    expires_delta: Optional[timedelta] = None,
    default_project_id: Optional[int] = None,
    project_id: Optional[int] = None,
) -> tuple[str, str, datetime]:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_EXPIRATION_DAYS)

    jti = str(uuid.uuid4())

    to_encode = {
        "sub": str(user_id),
        "username": username,
        "is_superuser": is_superuser,
        "role": "web_user",
        "aud": "postgrest",
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "jti": jti,
    }
    if default_project_id is not None:
        to_encode["default_project_id"] = default_project_id
    if project_id is not None:
        to_encode["project_id"] = project_id

    encoded_jwt = jwt.encode(
        to_encode,
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM
    )

    return encoded_jwt, jti, expire


def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
            audience="postgrest"
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
