from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List


class TokenBase(BaseModel):
    """Base Token schema with common fields."""

    token_name: Optional[str] = Field(None, max_length=255, description="Optional name for the token")


class TokenCreate(TokenBase):
    """Schema for token creation requests."""

    pass


class TokenResponse(BaseModel):
    """Schema for token data in API responses."""

    id: int
    user_id: int
    token_name: Optional[str]
    jti: str
    is_revoked: bool
    created_at: datetime
    expires_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2 (was orm_mode in v1)


class TokenWithJWT(TokenResponse):
    """Schema for token response including the actual JWT string."""

    access_token: str
    token_type: str = "bearer"


class TokenListResponse(BaseModel):
    """Schema for listing multiple tokens."""

    tokens: List[TokenResponse]
    total: int


class TokenRevokeRequest(BaseModel):
    """Schema for token revocation requests."""

    token_id: int = Field(..., description="ID of the token to revoke")


class TokenInDB(TokenBase):
    """Schema for token data stored in database."""

    id: int
    user_id: int
    jti: str
    is_revoked: bool
    created_at: datetime
    expires_at: datetime

    class Config:
        from_attributes = True
