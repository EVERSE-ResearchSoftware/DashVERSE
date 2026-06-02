from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import List


class ProjectResponse(BaseModel):

    id: int
    name: str
    owner_user_id: int
    is_public: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProjectListResponse(BaseModel):

    projects: List[ProjectResponse]
    total: int


class ProjectCreate(BaseModel):

    name: str = Field(..., min_length=1, max_length=255)
    is_public: bool = Field(default=False)


class ProjectUpdate(BaseModel):

    is_public: bool | None = Field(None, description="Public visibility flag")
    name: str | None = Field(None, min_length=1, max_length=255)
