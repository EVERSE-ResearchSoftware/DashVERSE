from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.project import Project
from app.schemas.project import (
    ProjectResponse,
    ProjectListResponse,
    ProjectCreate,
    ProjectUpdate,
)

router = APIRouter(prefix="/api/projects", tags=["Projects"])


def _owned_project(db: Session, user: User, project_id: int) -> Project:
    project = (
        db.query(Project)
        .filter(Project.id == project_id, Project.owner_user_id == user.id)
        .first()
    )
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found or does not belong to current user",
        )
    return project


@router.get("/", response_model=ProjectListResponse, summary="List the caller's projects")
def list_projects(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProjectListResponse:
    projects = (
        db.query(Project)
        .filter(Project.owner_user_id == current_user.id)
        .order_by(Project.id)
        .all()
    )
    return ProjectListResponse(
        projects=[ProjectResponse.model_validate(p) for p in projects],
        total=len(projects),
    )


@router.get("/me", response_model=ProjectResponse, summary="Get the caller's default project")
def get_my_project(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProjectResponse:
    project = (
        db.query(Project)
        .filter(Project.owner_user_id == current_user.id)
        .order_by(Project.id)
        .first()
    )
    if not project:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No default project for this user",
        )
    return ProjectResponse.model_validate(project)


@router.post(
    "/",
    response_model=ProjectResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new project",
)
def create_project(
    payload: ProjectCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProjectResponse:
    project = Project(
        name=payload.name,
        owner_user_id=current_user.id,
        is_public=payload.is_public,
    )
    db.add(project)
    db.commit()
    db.refresh(project)
    return ProjectResponse.model_validate(project)


@router.patch("/{project_id}", response_model=ProjectResponse, summary="Update a project's visibility or name")
def update_project(
    project_id: int,
    payload: ProjectUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProjectResponse:
    project = _owned_project(db, current_user, project_id)
    if payload.is_public is not None:
        project.is_public = payload.is_public
    if payload.name is not None:
        project.name = payload.name
    db.commit()
    db.refresh(project)
    return ProjectResponse.model_validate(project)


@router.delete(
    "/{project_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a project",
)
def delete_project(
    project_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    project = _owned_project(db, current_user, project_id)

    own_count = (
        db.query(Project)
        .filter(Project.owner_user_id == current_user.id)
        .count()
    )
    if own_count <= 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete your only project",
        )

    assessment_count = db.execute(
        text("SELECT COUNT(*) FROM api.assessment_raw WHERE project_id = :pid"),
        {"pid": project_id},
    ).scalar() or 0
    if assessment_count > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Project still has {assessment_count} assessment(s). "
                "Move them to another project first."
            ),
        )

    db.delete(project)
    db.commit()
    return {"message": "Project deleted", "project_id": project_id}
