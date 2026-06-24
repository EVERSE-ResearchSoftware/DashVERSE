from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Project(Base):

    __tablename__ = "projects"
    __table_args__ = {"schema": "auth"}

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    owner_user_id = Column(
        Integer,
        ForeignKey("auth.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    visibility = Column(String(20), nullable=False, default="public")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    owner = relationship("User", backref="projects")

    def __repr__(self):
        return f"<Project(id={self.id}, name='{self.name}', owner_user_id={self.owner_user_id}, visibility='{self.visibility}')>"
