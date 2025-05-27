"""
Module: models/content_relation
Contains the ContentRelation domain model which relates an Indicator, a Dimension, and a Software.
Includes both the Pydantic model for validation and the SQLAlchemy model for persistence.
"""

from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, Integer, ForeignKey
from .base import Base


class ContentRelationModel(PydanticBaseModel):
    """
    Pydantic model for validating ContentRelation data.

    Attributes:
        id (int): Unique identifier.
        indicator_id (int): The related Indicator's ID.
        dimension_id (int): The related Dimension's ID.
        software_id (int): The related Software's ID.
    """

    id: int
    indicator_id: int
    dimension_id: int
    software_id: int


SCHEMA_NAME = "everse"


class ContentRelation(Base):
    """
    SQLAlchemy model for ContentRelation.

    Attributes correspond to columns in the 'content_relation' table.
    """

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
