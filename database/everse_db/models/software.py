"""
Software model with Pydantic validation and SQLAlchemy persistence.
"""

from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, String, Integer, Text, DateTime
from sqlalchemy.dialects.postgresql import ARRAY
from .base import Base


class SoftwareModel(PydanticBaseModel):
    """Pydantic model for Software validation."""

    id: Optional[int] = None
    identifier: str
    name: str
    description: Optional[str] = None
    version: Optional[str] = None
    license: Optional[str] = None
    repository_url: Optional[str] = None
    homepage_url: Optional[str] = None
    programming_language: Optional[List[str]] = None


SCHEMA_NAME = "api"


class Software(Base):
    """SQLAlchemy model for the software table."""

    __tablename__ = "software"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    identifier = Column(String, nullable=False, unique=True, index=True)
    name = Column(String, nullable=False)
    description = Column(Text)
    version = Column(String)
    license = Column(String)
    repository_url = Column(String)
    homepage_url = Column(String)
    programming_language = Column(ARRAY(String))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
