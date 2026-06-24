from typing import Optional

from fastapi import APIRouter, Depends, Header
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.user import User

router = APIRouter(prefix="/api/stats", tags=["Stats"])


def _maybe_user(
    db: Session,
    authorization: Optional[str],
) -> Optional[User]:
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_access_token(token)
    if not payload:
        return None
    sub = payload.get("sub")
    if sub is None:
        return None
    try:
        uid = int(sub)
    except (TypeError, ValueError):
        return None
    return db.query(User).filter(User.id == uid, User.is_active == True).first()


@router.get("/home")
def home_stats(
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(default=None),
):
    public = db.execute(text(
        """
        SELECT
          COUNT(DISTINCT assessment_id) AS public_assessments,
          COUNT(DISTINCT software_name) AS public_software
        FROM api.assessment_checks
        WHERE effective_visibility = 'public'
        """
    )).first()
    catalog = db.execute(text(
        "SELECT (SELECT COUNT(*) FROM api.indicators) AS catalog_indicators,"
        " (SELECT COUNT(*) FROM api.dimensions)  AS catalog_dimensions"
    )).first()

    payload = {
        "public_assessments": public.public_assessments or 0,
        "public_software": public.public_software or 0,
        "catalog_indicators": catalog.catalog_indicators or 0,
        "catalog_dimensions": catalog.catalog_dimensions or 0,
    }

    user = _maybe_user(db, authorization)
    if user is None:
        return payload

    mine = db.execute(
        text(
            """
            WITH my_checks AS (
              SELECT outcome
              FROM api.assessment_checks
              WHERE author_user_id = :uid
            )
            SELECT
              (SELECT COUNT(*) FROM auth.projects
                WHERE owner_user_id = :uid)              AS my_projects,
              (SELECT COUNT(DISTINCT software_name)
                FROM api.assessment_checks
                WHERE author_user_id = :uid)             AS my_software,
              (SELECT COUNT(DISTINCT assessment_id)
                FROM api.assessment_checks
                WHERE author_user_id = :uid)             AS my_assessments,
              (SELECT MAX(assessed_at)
                FROM api.assessment_checks
                WHERE author_user_id = :uid)             AS my_last_assessment_at,
              (SELECT COUNT(*) FROM my_checks)           AS my_checks,
              (SELECT COUNT(*) FROM my_checks
                WHERE outcome = 'Pass')                  AS my_passed,
              (SELECT COUNT(*) FROM my_checks
                WHERE outcome = 'Fail')                  AS my_failed
            """
        ),
        {"uid": user.id},
    ).first()
    my_passed = mine.my_passed or 0
    my_failed = mine.my_failed or 0
    my_decided = my_passed + my_failed
    payload.update(
        my_projects=mine.my_projects or 0,
        my_software=mine.my_software or 0,
        my_assessments=mine.my_assessments or 0,
        my_last_assessment_at=(
            mine.my_last_assessment_at.isoformat()
            if mine.my_last_assessment_at else None
        ),
        my_checks=mine.my_checks or 0,
        my_passed=my_passed,
        my_failed=my_failed,
        my_pass_rate=(my_passed / my_decided) if my_decided else None,
    )

    recent = db.execute(
        text(
            """
            SELECT
              assessment_id,
              software_name,
              MAX(assessed_at) AS assessed_at,
              COUNT(*) FILTER (WHERE outcome = 'Pass') AS passed,
              COUNT(*) FILTER (WHERE outcome = 'Fail') AS failed,
              COUNT(*) FILTER (WHERE outcome = 'Not applicable') AS not_applicable
            FROM api.assessment_checks
            WHERE author_user_id = :uid
            GROUP BY assessment_id, software_name
            ORDER BY assessed_at DESC NULLS LAST
            LIMIT 10
            """
        ),
        {"uid": user.id},
    ).all()
    payload["my_recent"] = [
        {
            "assessment_id": r.assessment_id,
            "software_name": r.software_name,
            "assessed_at": r.assessed_at.isoformat() if r.assessed_at else None,
            "passed": r.passed or 0,
            "failed": r.failed or 0,
            "not_applicable": r.not_applicable or 0,
        }
        for r in recent
    ]
    return payload
