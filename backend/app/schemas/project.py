from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import List, Literal


Visibility = Literal["private", "authenticated", "public"]


class ProjectResponse(BaseModel):

    id: int
    name: str
    owner_user_id: int
    visibility: Visibility
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProjectListResponse(BaseModel):

    projects: List[ProjectResponse]
    total: int


class ProjectCreate(BaseModel):

    name: str = Field(..., min_length=1, max_length=255)
    visibility: Visibility = Field(default="public")


class ProjectUpdate(BaseModel):

    visibility: Visibility | None = Field(None, description="Project visibility tier")
    name: str | None = Field(None, min_length=1, max_length=255)


class SoftwareEntry(BaseModel):

    software_name: str
    assessment_count: int
    project_id: int | None
    project_name: str | None
    visibility: Visibility | None = None


class SoftwareListResponse(BaseModel):
    software: List[SoftwareEntry]
    total: int


class AssignSoftwareRequest(BaseModel):
    software_name: str = Field(..., min_length=1, max_length=255)


class SetSoftwareVisibilityRequest(BaseModel):

    software_name: str = Field(..., min_length=1, max_length=255)
    visibility: Visibility | None = Field(
        None,
        description=(
            "'private' | 'authenticated' | 'public' set the override; "
            "null clears the override and inherits the project's tier."
        ),
    )
