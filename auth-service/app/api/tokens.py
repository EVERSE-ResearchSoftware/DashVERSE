from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.security import create_access_token
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.token import Token
from app.models.project import Project
from app.schemas.token import (
    TokenCreate,
    TokenResponse,
    TokenWithJWT,
    TokenListResponse,
    TokenRevokeRequest
)

router = APIRouter(prefix="/api/tokens", tags=["Tokens"])

MAX_ACTIVE_API_TOKENS = 20


@router.post(
    "/",
    response_model=TokenWithJWT,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a new access token"
)
def generate_token(
    token_data: TokenCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> TokenWithJWT:
    active = (
        db.query(Token)
        .filter(
            Token.user_id == current_user.id,
            Token.token_type == "api",
            Token.is_revoked == False,  # noqa: E712 - sqlalchemy needs ==
        )
        .count()
    )
    if active >= MAX_ACTIVE_API_TOKENS:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"You already have {MAX_ACTIVE_API_TOKENS} active tokens. Revoke one before issuing another.",
        )

    project: Project | None = None
    if token_data.project_id is not None:
        project = (
            db.query(Project)
            .filter(
                Project.id == token_data.project_id,
                Project.owner_user_id == current_user.id,
            )
            .first()
        )
        if not project:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Project not found or does not belong to current user",
            )
    else:
        project = (
            db.query(Project)
            .filter(Project.owner_user_id == current_user.id)
            .order_by(Project.id)
            .first()
        )

    if project is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You need to create a project before generating an API token.",
        )

    project_id = project.id

    expires_delta = (
        timedelta(days=token_data.ttl_days) if token_data.ttl_days else None
    )
    jwt_token, jti, expires_at = create_access_token(
        user_id=current_user.id,
        username=current_user.username,
        is_superuser=current_user.is_superuser,
        default_project_id=project_id,
        project_id=project_id,
        expires_delta=expires_delta,
    )

    token_record = Token(
        user_id=current_user.id,
        token_name=token_data.token_name,
        jti=jti,
        expires_at=expires_at,
        is_revoked=False,
        token_type="api",
        project_id=project_id,
    )
    db.add(token_record)
    db.commit()
    db.refresh(token_record)

    return TokenWithJWT(
        id=token_record.id,
        user_id=token_record.user_id,
        token_name=token_record.token_name,
        project_id=token_record.project_id,
        jti=token_record.jti,
        is_revoked=token_record.is_revoked,
        created_at=token_record.created_at,
        expires_at=token_record.expires_at,
        access_token=jwt_token,
        token_type="bearer"
    )


@router.get(
    "/",
    response_model=TokenListResponse,
    summary="List all tokens for current user"
)
def list_tokens(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> TokenListResponse:
    tokens = (
        db.query(Token)
        .filter(Token.user_id == current_user.id, Token.token_type == "api")
        .order_by(Token.created_at.desc())
        .all()
    )

    token_responses = [TokenResponse.model_validate(token) for token in tokens]

    return TokenListResponse(
        tokens=token_responses,
        total=len(token_responses)
    )


@router.post(
    "/revoke",
    status_code=status.HTTP_200_OK,
    summary="Revoke a token"
)
def revoke_token(
    revoke_request: TokenRevokeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    token = db.query(Token).filter(
        Token.id == revoke_request.token_id,
        Token.user_id == current_user.id,
        Token.token_type == "api",
    ).first()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found or does not belong to current user"
        )

    if token.is_revoked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token is already revoked"
        )

    token.is_revoked = True
    db.commit()

    return {
        "message": "Token revoked successfully",
        "token_id": token.id,
        "token_name": token.token_name,
        "jti": token.jti
    }


@router.delete(
    "/{token_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a token permanently"
)
def delete_token(
    token_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    token = db.query(Token).filter(
        Token.id == token_id,
        Token.user_id == current_user.id,
        Token.token_type == "api",
    ).first()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found or does not belong to current user"
        )

    if not token.is_revoked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete active token. Revoke it first."
        )

    token_info = {
        "token_id": token.id,
        "token_name": token.token_name,
        "jti": token.jti
    }

    db.delete(token)
    db.commit()

    return {
        "message": "Token deleted successfully",
        **token_info
    }
