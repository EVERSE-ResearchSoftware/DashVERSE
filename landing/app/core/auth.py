from fastapi import Request
import jwt
import logging

from app.core.config import settings

log = logging.getLogger(__name__)


def verify_jwt(token: str) -> dict | None:
    if not token or not settings.jwt_secret:
        return None
    try:
        return jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            audience="postgrest",
        )
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError as exc:
        log.debug("rejected access_token: %s", exc)
        return None


def current_user(request: Request) -> dict | None:
    cached = getattr(request.state, "_user", None)
    if cached is not None:
        return cached or None
    token = request.cookies.get("access_token")
    payload = verify_jwt(token) if token else None
    if payload:
        user = {
            "sub": payload.get("sub"),
            "username": payload.get("username"),
            "is_superuser": payload.get("is_superuser", False),
            "token": token,
        }
    else:
        user = None
    request.state._user = user or False
    return user
