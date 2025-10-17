"""
Module: models/dimension
Contains the Dimension domain model including its Pydantic model for validation and
the SQLAlchemy model for persistence.
"""

from typing import List, Optional
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, String, Integer
from sqlalchemy.dialects.postgresql import ARRAY
from .base import Base


class DimensionModel(PydanticBaseModel):
    """
    Pydantic model for validating Dimension data.

    Attributes:
        id (Optional[int]): Unique identifier.
        identifier (str): A unique code for the dimension.
        name (str): The name of the dimension.
        description (str): A description of the dimension.
        source (Optional[List[str]]): Source information.
    """

    id: Optional[int] = None
    identifier: str
    name: str
    description: str
    source: Optional[List[str]] = None


SCHEMA_NAME = "everse"


class Dimension(Base):
    """
    SQLAlchemy model for the Dimension.

    Attributes correspond to columns in the 'dimensions' table.
    """

    __tablename__ = "dimensions"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    identifier = Column(String, nullable=False, unique=True, index=True)
    name = Column(String)
    description = Column(String)
    source = Column(ARRAY(String))
