from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.core.config import settings
from app.models.failed_login_attempt import FailedLoginAttempt


def record_failed_login(db, username, ip_address=None):
    """Record failed login attempt."""
    attempt = FailedLoginAttempt(
        username=username,
        ip_address=ip_address,
        attempt_time=datetime.utcnow()
    )
    db.add(attempt)
    db.commit()


def get_recent_failed_attempts(db: Session, username: str, window_minutes: int = 15):
    """Get count of recent failed login attempts."""
    cutoff_time = datetime.utcnow() - timedelta(minutes=window_minutes)

    count = db.query(FailedLoginAttempt).filter(
        and_(
            FailedLoginAttempt.username == username,
            FailedLoginAttempt.attempt_time >= cutoff_time
        )
    ).count()

    return count


def is_account_locked(db: Session, username: str) -> tuple[bool, Optional[datetime]]:
    """Check if acount is currently locked."""
    # Get the most recent locked_until timestamp
    latest_attempt = db.query(FailedLoginAttempt).filter(
        and_(
            FailedLoginAttempt.username == username,
            FailedLoginAttempt.locked_until.isnot(None)
        )
    ).order_by(FailedLoginAttempt.locked_until.desc()).first()

    if not latest_attempt or not latest_attempt.locked_until:
        return False, None

    # quick fix - check if lock is still active
    if latest_attempt.locked_until > datetime.utcnow():
        return True, latest_attempt.locked_until

    return False, None


def lock_account(db, username, duration_minutes=None):
    """Lock account after too many failed attempts."""
    if duration_minutes is None:
        duration_minutes = settings.LOCKOUT_DURATION_MINUTES

    locked_until = datetime.utcnow() + timedelta(minutes=duration_minutes)

    # Create a lockout record
    lockout_record = FailedLoginAttempt(
        username=username,
        attempt_time=datetime.utcnow(),
        locked_until=locked_until
    )
    db.add(lockout_record)
    db.commit()

    return locked_until


def clear_failed_attempts(db, username):
    """Clear failed attempts after successful login."""
    db.query(FailedLoginAttempt).filter(
        FailedLoginAttempt.username == username
    ).delete()
    db.commit()


def check_and_handle_login_attempt(
    db: Session,
    username: str,
    ip_address: Optional[str] = None
) -> tuple[bool, Optional[str], Optional[datetime]]:
    """
    Check if login attempt is allowed and handle lockout logic.

    Should be called BEFORE attempting authentication.
    Returns (is_allowed, error_message, locked_until).
    """
    # Check if account is currently locked
    is_locked, locked_until = is_account_locked(db, username)

    if is_locked:
        minutes_remaining = int((locked_until - datetime.utcnow()).total_seconds() / 60) + 1
        error_msg = (
            f"Account is locked due to too many failed login attempts. "
            f"Please try again in {minutes_remaining} minute(s)."
        )
        return False, error_msg, locked_until

    # Check recent failed attempts
    recent_failures = get_recent_failed_attempts(db, username)

    if recent_failures >= settings.MAX_LOGIN_ATTEMPTS:
        # Lock the account
        locked_until = lock_account(db, username)
        minutes_remaining = settings.LOCKOUT_DURATION_MINUTES
        error_msg = (
            f"Account locked due to {settings.MAX_LOGIN_ATTEMPTS} failed login attempts. "
            f"Please try again in {minutes_remaining} minute(s)."
        )
        return False, error_msg, locked_until

    # Login attempt is allowed
    return True, None, None
