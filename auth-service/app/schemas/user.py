from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional

from app.core.config import settings


class UserBase(BaseModel):

    username: str = Field(..., min_length=3, max_length=255, description="Username for authentication")
    email: EmailStr = Field(..., description="Email address")


class UserCreate(UserBase):

    password: str = Field(
        ...,
        min_length=settings.PASSWORD_MIN_LENGTH,
        description=f"Password (minimum {settings.PASSWORD_MIN_LENGTH} characters)",
        repr=False
    )

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < settings.PASSWORD_MIN_LENGTH:
            raise ValueError(f"Password must be at least {settings.PASSWORD_MIN_LENGTH} characters")
        return v


class UserLogin(BaseModel):

    username: str = Field(..., description="Username")
    password: str = Field(..., description="Password", repr=False)


class UserUpdate(BaseModel):

    email: Optional[EmailStr] = Field(None, description="New email address")
    password: Optional[str] = Field(
        None,
        min_length=settings.PASSWORD_MIN_LENGTH,
        description=f"New password (minimum {settings.PASSWORD_MIN_LENGTH} characters)",
        repr=False
    )

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and len(v) < settings.PASSWORD_MIN_LENGTH:
            raise ValueError(f"Password must be at least {settings.PASSWORD_MIN_LENGTH} characters")
        return v


class UserResponse(UserBase):

    id: int
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserInDB(UserBase):

    id: int
    hashed_password: str = Field(..., repr=False)
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
