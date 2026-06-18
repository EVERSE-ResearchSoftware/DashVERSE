from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func

from app.core.database import Base


class SoftwareVisibility(Base):

    __tablename__ = "software_visibility"
    __table_args__ = {"schema": "auth"}

    software_name = Column(String(255), primary_key=True)
    owner_user_id = Column(
        Integer,
        ForeignKey("auth.users.id", ondelete="CASCADE"),
        primary_key=True,
        index=True,
    )
    visibility = Column(String(20), nullable=False, default="private")
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    def __repr__(self):
        return (
            f"<SoftwareVisibility(software_name='{self.software_name}', "
            f"owner_user_id={self.owner_user_id}, visibility='{self.visibility}')>"
        )
