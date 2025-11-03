"""
ContentRelation model linking Indicator, Dimension, and Software.
"""

from typing import Optional
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, Integer, ForeignKey
from .base import Base


class ContentRelationModel(PydanticBaseModel):
    """Pydantic model for ContentRelation validation."""

    id: Optional[int] = None
    indicator_id: int
    dimension_id: int
    software_id: int


SCHEMA_NAME = "api"


class ContentRelation(Base):
    """SQLAlchemy model for the content_relation table."""

    __tablename__ = "content_relation"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    indicator_id = Column(
        Integer, ForeignKey(f"{SCHEMA_NAME}.indicators.id"), nullable=False
    )
    dimension_id = Column(
        Integer, ForeignKey(f"{SCHEMA_NAME}.dimensions.id"), nullable=False
    )
    software_id = Column(
        Integer, ForeignKey(f"{SCHEMA_NAME}.software.id"), nullable=False
    )
