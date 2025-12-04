from passlib.context import CryptContext

from app.core.config import settings

# argon2 for password hashing
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__memory_cost=65536,  # 64 MB
    argon2__time_cost=3,  # 3 iterations
    argon2__parallelism=4,  # 4 parallel threads
)


def hash_password(password):
    # Use Argon2id for hashing
    return pwd_context.hash(password)


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def validate_password_strength(password: str) -> tuple[bool, str | None]:
    min_length = settings.PASSWORD_MIN_LENGTH
    if len(password) < min_length:
        return False, f"Password must be at least {min_length} characters"
    return True, None
