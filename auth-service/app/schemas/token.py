from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import Optional, List


class TokenBase(BaseModel):

    token_name: Optional[str] = Field(None, max_length=255, description="Optional name for the token")


class TokenCreate(TokenBase):

    pass


class TokenResponse(BaseModel):

    id: int
    user_id: int
    token_name: Optional[str]
    jti: str
    is_revoked: bool
    created_at: datetime
    expires_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TokenWithJWT(TokenResponse):

    access_token: str
    token_type: str = "bearer"


class TokenListResponse(BaseModel):

    tokens: List[TokenResponse]
    total: int


class TokenRevokeRequest(BaseModel):

    token_id: int = Field(..., description="ID of the token to revoke")


class TokenInDB(TokenBase):

    id: int
    user_id: int
    jti: str
    is_revoked: bool
    created_at: datetime
    expires_at: datetime

    model_config = ConfigDict(from_attributes=True)
