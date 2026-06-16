from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import Optional, List


class TokenBase(BaseModel):

    token_name: Optional[str] = Field(None, max_length=255, description="Optional name for the token")


class TokenCreate(TokenBase):

    project_id: Optional[int] = Field(
        None,
        description="Project to scope this token to. Assessments submitted with the token go to this project. Defaults to the caller's primary project when omitted.",
    )
    ttl_days: Optional[int] = Field(
        None,
        ge=1,
        le=90,
        description="Token lifetime in days (1-90). Defaults to the system-wide JWT expiry when omitted.",
    )


class TokenResponse(BaseModel):

    id: int
    user_id: int
    token_name: Optional[str]
    project_id: Optional[int] = None
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
