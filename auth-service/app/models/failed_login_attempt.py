from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from app.core.database import Base


class FailedLoginAttempt(Base):
    """Failed login tracking for account lockout."""

    __tablename__ = "failed_login_attempts"
    __table_args__ = {"schema": "auth"}

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255), nullable=False, index=True)
    ip_address = Column(String(45), nullable=True)  # supports both IPv4 and IPv6
    attempt_time = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    locked_until = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<FailedLoginAttempt(id={self.id}, username='{self.username}', attempt_time={self.attempt_time})>"
