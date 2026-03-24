from fastapi import APIRouter, Depends, Request, Form, Response, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import Optional
import os

from app.core.database import get_db
from app.core.config import settings
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    validate_password_strength
)
from app.core.lockout import (
    check_and_handle_login_attempt,
    record_failed_login,
    clear_failed_attempts
)
from app.api.dependencies import get_client_ip
from app.models.user import User
from app.models.token import Token

router = APIRouter(tags=["Web Interface"])

# Get the absolute path to templates directory
templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)


def get_user_from_session(request: Request, db: Session) -> Optional[User]:
    """Retrive user from session cookie."""
    token = request.cookies.get("access_token")
    if not token:
        return None

    # Decode token and get user
    from app.core.security import decode_access_token
    payload = decode_access_token(token)
    if not payload:
        return None

    user_id = payload.get("sub")
    if not user_id:
        return None

    user = db.query(User).filter(User.id == int(user_id)).first()
    # temp solution - just check active status
    return user if user and user.is_active else None


@router.get("/", response_class=HTMLResponse)
async def root(request: Request, db: Session = Depends(get_db)):
    user = get_user_from_session(request, db)
    if user:
        return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)
    return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)


@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, db: Session = Depends(get_db)):
    user = get_user_from_session(request, db)
    if user:
        return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)

    return templates.TemplateResponse(
        "login.html",
        {"request": request, "user": None}
    )


@router.post("/login", response_class=HTMLResponse)
async def login_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db)
):
    client_ip = get_client_ip(request)

    # Check if login attempt is allowed
    is_allowed, error_msg, locked_until = check_and_handle_login_attempt(
        db, username, client_ip
    )

    if not is_allowed:
        return templates.TemplateResponse(
            "login.html",
            {
                "request": request,
                "user": None,
                "error": error_msg,
                "username": username
            }
        )

    # Get user and verify password
    user = db.query(User).filter(User.username == username).first()

    if not user or not verify_password(password, user.hashed_password):
        record_failed_login(db, username, client_ip)
        return templates.TemplateResponse(
            "login.html",
            {
                "request": request,
                "user": None,
                "error": "Incorrect username or password",
                "username": username
            }
        )

    if not user.is_active:
        return templates.TemplateResponse(
            "login.html",
            {
                "request": request,
                "user": None,
                "error": "User account is inactive",
                "username": username
            }
        )

    # Successful login
    clear_failed_attempts(db, username)

    # Create session JWT token (not stored in database - for web session only)
    session_token, _, _ = create_access_token(
        user_id=user.id,
        username=user.username,
        is_superuser=user.is_superuser
    )

    # Redirect to dashboard with session token in cookie
    response = RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)
    response.set_cookie(
        key="access_token",
        value=session_token,
        httponly=True,
        max_age=settings.JWT_EXPIRATION_DAYS * 24 * 60 * 60,
        samesite="lax"
    )
    return response


@router.get("/register", response_class=HTMLResponse)
async def register_page(request: Request, db: Session = Depends(get_db)):
    """Display registration page."""
    user = get_user_from_session(request, db)
    if user:
        return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)

    return templates.TemplateResponse(
        "register.html",
        {
            "request": request,
            "user": None,
            "password_min_length": settings.PASSWORD_MIN_LENGTH
        }
    )


@router.post("/register", response_class=HTMLResponse)
async def register_submit(
    request: Request,
    username: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
    db: Session = Depends(get_db)
):
    """Handle registration form."""
    # Validate passwords match
    if password != confirm_password:
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "error": "Passwords do not match",
                "username": username,
                "email": email,
                "password_min_length": settings.PASSWORD_MIN_LENGTH
            }
        )

    # Validate password strength
    is_valid, error_msg = validate_password_strength(password)
    if not is_valid:
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "error": error_msg,
                "username": username,
                "email": email,
                "password_min_length": settings.PASSWORD_MIN_LENGTH
            }
        )

    # Check if username exists
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "error": "Username already registered",
                "email": email,
                "password_min_length": settings.PASSWORD_MIN_LENGTH
            }
        )

    # Check if email exists
    existing_email = db.query(User).filter(User.email == email).first()
    if existing_email:
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "error": "Email already registered",
                "username": username,
                "password_min_length": settings.PASSWORD_MIN_LENGTH
            }
        )

    # Create new user
    hashed_password = hash_password(password)
    new_user = User(
        username=username,
        email=email,
        hashed_password=hashed_password,
        is_active=True,
        is_superuser=False
    )

    try:
        db.add(new_user)
        db.commit()
    except IntegrityError:
        db.rollback()
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "error": "Username or email already registered",
                "password_min_length": settings.PASSWORD_MIN_LENGTH
            }
        )

    # Redirect to login with success message
    return RedirectResponse(
        url="/login?message=Registration successful! Please login.",
        status_code=status.HTTP_302_FOUND
    )


@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard_page(request: Request, db: Session = Depends(get_db)):
    """Display dashboard with token management."""
    user = get_user_from_session(request, db)
    if not user:
        return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)

    # Get user's tokens
    tokens = db.query(Token).filter(Token.user_id == user.id).order_by(Token.created_at.desc()).all()

    # Check for new token in query params
    new_token = request.query_params.get("token")

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "user": user,
            "tokens": tokens,
            "new_token": new_token
        }
    )


@router.post("/tokens/generate")
async def generate_token_web(request: Request, db: Session = Depends(get_db)):
    """Generate new token from web UI."""
    user = get_user_from_session(request, db)
    if not user:
        return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)

    # Create JWT token
    jwt_token, jti, expires_at = create_access_token(
        user_id=user.id,
        username=user.username,
        is_superuser=user.is_superuser
    )

    # Store token in database
    token_record = Token(
        user_id=user.id,
        jti=jti,
        expires_at=expires_at,
        is_revoked=False
    )
    db.add(token_record)
    db.commit()

    # Redirect to dashboard with new token
    return RedirectResponse(
        url=f"/dashboard?token={jwt_token}",
        status_code=status.HTTP_302_FOUND
    )


@router.post("/tokens/revoke")
async def revoke_token_web(
    request: Request,
    token_id: int = Form(...),
    db: Session = Depends(get_db)
):
    """Revoke token from web UI."""
    user = get_user_from_session(request, db)
    if not user:
        return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)

    # Get token
    token = db.query(Token).filter(
        Token.id == token_id,
        Token.user_id == user.id
    ).first()

    if token and not token.is_revoked:
        token.is_revoked = True
        db.commit()

    return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)


@router.post("/tokens/delete")
async def delete_token_web(
    request: Request,
    token_id: int = Form(...),
    db: Session = Depends(get_db)
):
    """Delete revoked token from web UI."""
    user = get_user_from_session(request, db)
    if not user:
        return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)

    # Get token - only allow deletion of revoked tokens
    token = db.query(Token).filter(
        Token.id == token_id,
        Token.user_id == user.id,
        Token.is_revoked == True
    ).first()

    if token:
        db.delete(token)
        db.commit()

    return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)


@router.get("/logout")
async def logout(request: Request):
    """Logout user by clearing cookie."""
    response = RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)
    response.delete_cookie("access_token")
    return response
