from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.security import create_access_token
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.token import Token
from app.schemas.token import (
    TokenCreate,
    TokenResponse,
    TokenWithJWT,
    TokenListResponse,
    TokenRevokeRequest
)

router = APIRouter(prefix="/api/tokens", tags=["Tokens"])


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
    """
    Generate a new JWT access token for the authenticated user.
    Requires bearer token in Authorization header.
    Optional token_name for identifying the token later.
    """
    # Create JWT access token
    jwt_token, jti, expires_at = create_access_token(
        user_id=current_user.id,
        username=current_user.username,
        is_superuser=current_user.is_superuser
    )

    # Store token in database for tracking and revocation
    token_record = Token(
        user_id=current_user.id,
        token_name=token_data.token_name,
        jti=jti,
        expires_at=expires_at,
        is_revoked=False
    )
    db.add(token_record)
    db.commit()
    db.refresh(token_record)

    # Return token with JWT
    return TokenWithJWT(
        id=token_record.id,
        user_id=token_record.user_id,
        token_name=token_record.token_name,
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
    """List all tokens for the current user (both active and revoked)."""
    tokens = db.query(Token).filter(Token.user_id == current_user.id).order_by(Token.created_at.desc()).all()

    # Convert to response models
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
    """
    Revoke a token by ID. The token becomes invalid immediately.
    Users can only revoke their own tokens.
    Returns 404 if token not found, 400 if already revoked.
    """
    # Get the token from database
    token = db.query(Token).filter(
        Token.id == revoke_request.token_id,
        Token.user_id == current_user.id
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

    # Revoke the token
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
    """
    Delete a token permanently. Token must be revoked first.
    Consider keeping revoked tokens for audit trail instead of deleting.
    """
    # Get the token from database
    token = db.query(Token).filter(
        Token.id == token_id,
        Token.user_id == current_user.id
    ).first()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found or does not belong to current user"
        )

    # Only allow deletion of revoked tokens (for audit purposes)
    if not token.is_revoked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete active token. Revoke it first."
        )

    # Delete the token
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
