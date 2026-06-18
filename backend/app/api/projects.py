from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.project import Project
from app.models.software_visibility import SoftwareVisibility
from app.schemas.project import (
    ProjectResponse,
    ProjectListResponse,
    ProjectCreate,
    ProjectUpdate,
    SoftwareEntry,
    SoftwareListResponse,
    AssignSoftwareRequest,
    SetSoftwareVisibilityRequest,
)

router = APIRouter(prefix="/api/projects", tags=["Projects"])

MAX_PROJECTS_PER_USER = 50


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
    count = (
        db.query(Project)
        .filter(Project.owner_user_id == current_user.id)
        .count()
    )
    if count >= MAX_PROJECTS_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Project limit reached ({MAX_PROJECTS_PER_USER}). Delete an existing project first.",
        )
    project = Project(
        name=payload.name,
        owner_user_id=current_user.id,
        visibility=payload.visibility,
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
    if payload.visibility is not None:
        project.visibility = payload.visibility
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

    assigned = db.execute(
        text("SELECT COUNT(*) FROM api.assessment_raw WHERE project_id = :pid"),
        {"pid": project_id},
    ).scalar() or 0
    if assigned:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"Cannot delete project: {assigned} assessment(s) still assigned. "
                "Move or delete the software first."
            ),
        )

    db.delete(project)
    db.commit()
    return {
        "message": "Project deleted",
        "project_id": project_id,
    }


@router.get(
    "/me/software",
    response_model=SoftwareListResponse,
    summary="List the caller's assessed software and which project each currently belongs to",
)
def list_my_software(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SoftwareListResponse:
    rows = db.execute(
        text(
            """
            SELECT
                a.payload->'assessedSoftware'->>'name' AS software_name,
                COUNT(*) AS assessment_count,
                mode() WITHIN GROUP (ORDER BY a.project_id) AS project_id
            FROM api.assessment_raw a
            WHERE a.created_by = :uid
              AND a.payload->'assessedSoftware'->>'name' IS NOT NULL
            GROUP BY 1
            ORDER BY 1
            """
        ),
        {"uid": current_user.id},
    ).fetchall()

    project_lookup: dict[int, str] = {
        p.id: p.name
        for p in db.query(Project).filter(Project.owner_user_id == current_user.id).all()
    }

    visibility_lookup: dict[str, str] = {
        sv.software_name: sv.visibility
        for sv in db.query(SoftwareVisibility)
        .filter(SoftwareVisibility.owner_user_id == current_user.id)
        .all()
    }

    software = [
        SoftwareEntry(
            software_name=row.software_name,
            assessment_count=int(row.assessment_count),
            project_id=row.project_id,
            project_name=project_lookup.get(row.project_id) if row.project_id is not None else None,
            visibility=visibility_lookup.get(row.software_name),
        )
        for row in rows
    ]
    return SoftwareListResponse(software=software, total=len(software))


@router.post(
    "/{project_id}/software",
    status_code=status.HTTP_200_OK,
    summary="Reassign every assessment of one software (by the caller) to this project",
)
def assign_software(
    project_id: int,
    payload: AssignSoftwareRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    _owned_project(db, current_user, project_id)
    result = db.execute(
        text(
            """
            UPDATE api.assessment_raw
            SET project_id = :pid
            WHERE created_by = :uid
              AND payload->'assessedSoftware'->>'name' = :sw
            """
        ),
        {"pid": project_id, "uid": current_user.id, "sw": payload.software_name},
    )
    db.commit()
    return {
        "message": "Software reassigned",
        "project_id": project_id,
        "software_name": payload.software_name,
        "rows_updated": result.rowcount,
    }


@router.post(
    "/me/software/delete",
    status_code=status.HTTP_200_OK,
    summary="Delete every assessment of one software authored by the caller",
)
def delete_software_assessments(
    payload: AssignSoftwareRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    result = db.execute(
        text(
            """
            DELETE FROM api.assessment_raw
            WHERE created_by = :uid
              AND payload->'assessedSoftware'->>'name' = :sw
            """
        ),
        {"uid": current_user.id, "sw": payload.software_name},
    )
    db.commit()
    return {
        "message": "Assessments deleted",
        "software_name": payload.software_name,
        "rows_deleted": result.rowcount,
    }


@router.put(
    "/me/software/visibility",
    status_code=status.HTTP_200_OK,
    summary="Set or clear the public/private visibility override for one software",
)
def set_software_visibility(
    payload: SetSoftwareVisibilityRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    existing = (
        db.query(SoftwareVisibility)
        .filter(
            SoftwareVisibility.software_name == payload.software_name,
            SoftwareVisibility.owner_user_id == current_user.id,
        )
        .first()
    )
    if payload.visibility is None:
        if existing:
            db.delete(existing)
            db.commit()
            return {"message": "Override cleared", "software_name": payload.software_name}
        return {"message": "No override to clear", "software_name": payload.software_name}

    if existing:
        existing.visibility = payload.visibility
    else:
        existing = SoftwareVisibility(
            software_name=payload.software_name,
            owner_user_id=current_user.id,
            visibility=payload.visibility,
        )
        db.add(existing)
    db.commit()
    return {
        "message": "Override set",
        "software_name": payload.software_name,
        "visibility": existing.visibility,
    }
