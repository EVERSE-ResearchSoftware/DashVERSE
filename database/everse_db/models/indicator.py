"""
Indicator model with Pydantic validation and SQLAlchemy persistence.
"""

from typing import Any, Dict, Optional
from datetime import datetime
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, String, Integer, Text, DateTime
from sqlalchemy.dialects.postgresql import JSONB
from .base import Base


class IndicatorModel(PydanticBaseModel):
    """Pydantic model for Indicator validation."""

    id: Optional[int] = None
    identifier: str
    name: str
    description: Optional[str] = None
    status: Optional[str] = None
    quality_dimension: Optional[str] = None
    contact: Optional[Dict[str, Any]] = None
    source: Optional[Dict[str, Any]] = None


SCHEMA_NAME = "api"


class Indicator(Base):
    """SQLAlchemy model for the indicators table."""

    __tablename__ = "indicators"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    identifier = Column(String, nullable=False, unique=True, index=True)
    name = Column(String, nullable=False)
    description = Column(Text)
    status = Column(String)
    quality_dimension = Column(String)
    contact = Column(JSONB)
    source = Column(JSONB)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
