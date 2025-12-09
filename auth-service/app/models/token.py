from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Token(Base):
    """Token model for JWT management."""

    __tablename__ = "tokens"
    __table_args__ = {"schema": "auth"}

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("auth.users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_name = Column(String(255), nullable=True)
    jti = Column(String(255), unique=True, nullable=False, index=True)
    is_revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

    # Relationships
    user = relationship("User", back_populates="tokens")

    def __repr__(self):
        return f"<Token(id={self.id}, jti='{self.jti}', user_id={self.user_id}, revoked={self.is_revoked})>"
