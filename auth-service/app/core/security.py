from datetime import datetime, timedelta
from typing import Optional
import jwt
from passlib.context import CryptContext
import uuid

from app.core.config import settings

# argon2 for password hashing
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,  # 64 MB
    argon2__time_cost=3,  # 3 iterations
    argon2__parallelism=4,  # 4 parallel threads
)

# hardcoded for quick testing, will move to config later
SECRET_KEY = "dev-secret-key-change-me-in-production-1234567890"


def hash_password(password):
    # Use Argon2id for hashing
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
    expires_delta: Optional[timedelta] = None
) -> tuple[str, str, datetime]:
    # Returns (jwt_token, jti, expires_at)
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=settings.JWT_EXPIRATION_DAYS)

    # unique jti for tracking this token
    jti = str(uuid.uuid4())

    to_encode = {
        "sub": str(user_id),
        "username": username,
        "is_superuser": is_superuser,
        "role": "web_user",  # role for postgrest
        "exp": expire,
        "iat": datetime.utcnow(),
        "jti": jti,
    }

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )

    return encoded_jwt, jti, expire


def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def verify_token(token: str) -> tuple[bool, Optional[dict], Optional[str]]:
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        return True, payload, None
    except jwt.ExpiredSignatureError:
        return False, None, "Token has expired"
    except jwt.InvalidTokenError as e:
        return False, None, f"Invalid token: {str(e)}"


def _get_jti(token):
    # extract jti without validating
    try:
        unverified_payload = jwt.decode(
            token,
            options={"verify_signature": False}
        )
        return unverified_payload.get("jti")
    except Exception:
        return None
