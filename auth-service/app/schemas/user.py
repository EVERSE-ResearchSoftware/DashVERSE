from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional

from app.core.config import settings


class UserBase(BaseModel):
    """Base User schema with common fields."""

    username: str = Field(..., min_length=3, max_length=255, description="Username for authentication")
    email: EmailStr = Field(..., description="Email address")


class UserCreate(UserBase):
    """Schema for user registration."""

    password: str = Field(
        ...,
        min_length=settings.PASSWORD_MIN_LENGTH,
        description=f"Password (minimum {settings.PASSWORD_MIN_LENGTH} characters)",
        repr=False  # Prevent password from appearing in logs/debug output
    )

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Validate password meets minimum requirements."""
        if len(v) < settings.PASSWORD_MIN_LENGTH:
            raise ValueError(f"Password must be at least {settings.PASSWORD_MIN_LENGTH} characters")
        return v


class UserLogin(BaseModel):
    """Schema for user login."""

    username: str = Field(..., description="Username")
    password: str = Field(..., description="Password", repr=False)  # Prevent password from appearing in logs


class UserUpdate(BaseModel):
    """Schema for user profile updates."""

    email: Optional[EmailStr] = Field(None, description="New email address")
    password: Optional[str] = Field(
        None,
        min_length=settings.PASSWORD_MIN_LENGTH,
        description=f"New password (minimum {settings.PASSWORD_MIN_LENGTH} characters)",
        repr=False  # Prevent password from appearing in logs/debug output
    )

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: Optional[str]) -> Optional[str]:
        """Validate password meets minimum requirements if provided."""
        if v is not None and len(v) < settings.PASSWORD_MIN_LENGTH:
            raise ValueError(f"Password must be at least {settings.PASSWORD_MIN_LENGTH} characters")
        return v


class UserResponse(UserBase):
    """Schema for user data in API responses."""

    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2 (was orm_mode in v1)


class UserInDB(UserBase):
    """Schema for user data stored in database (includes hashed password)."""

    id: int
    hashed_password: str = Field(..., repr=False)  # Prevent hash from appearing in logs
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
