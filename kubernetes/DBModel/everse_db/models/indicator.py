"""
Module: models/indicator
Contains the Indicator domain model, including its enums, Pydantic model for validation,
and SQLAlchemy model for persistence.
"""

from enum import Enum
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, String, Integer, DateTime
from sqlalchemy.dialects.postgresql import ARRAY, ENUM as PGEnum
from .base import Base

# --- Enums used by Indicator ---


class KeywordEnum(str, Enum):
    """
    Enumeration of possible keywords for an Indicator.
    """

    keyword1 = "keyword1"
    keyword2 = "keyword2"
    keyword3 = "keyword3"


class StatusEnum(str, Enum):
    """
    Enumeration for the status of an Indicator.
    """

    active = "active"
    deprecated = "deprecated"


class QualityDimensionEnum(str, Enum):
    """
    Enumeration for quality dimensions of an Indicator.
    """

    openness = "openness"
    FAIRness = "FAIRness"
    sustainability = "sustainability"


# --- Pydantic model for Indicator ---


class IndicatorModel(PydanticBaseModel):
    """
    Pydantic model for validating Indicator data.

    Attributes:
        id (Optional[int]): The unique identifier (automatically generated).
        identifier (str): A unique code for the indicator.
        name (str): The name of the indicator.
        description (str): A description of the indicator.
        keywords (Optional[List[KeywordEnum]]): A list of associated keywords.
        status (StatusEnum): The current status of the indicator.
        qualityDimensions (Optional[List[QualityDimensionEnum]]): Quality dimensions.
        releaseDate (Optional[datetime]): Release date of the indicator.
        version (str): Version information.
        doi (str): Digital Object Identifier.
    """

    id: Optional[int] = None
    identifier: str
    name: str
    description: str
    keywords: Optional[List[KeywordEnum]] = None
    status: StatusEnum
    qualityDimensions: Optional[List[QualityDimensionEnum]] = None
    releaseDate: Optional[datetime] = None
    version: str
    doi: str


# --- SQLAlchemy model for Indicator ---

SCHEMA_NAME = "everse"

#: PostgreSQL enum for the 'status' column based on StatusEnum.
status_enum_pg = PGEnum(StatusEnum, name="status_enum", create_type=True)


class Indicator(Base):
    """
    SQLAlchemy model for the Indicator.

    Attributes correspond to columns in the 'indicators' table.
    """

    __tablename__ = "indicators"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    identifier = Column(String, nullable=False, unique=True, index=True)
    name = Column(String)
    description = Column(String)
    keywords = Column(ARRAY(String))
    status = Column(status_enum_pg)
    qualityDimensions = Column(ARRAY(String))
    releaseDate = Column(DateTime, nullable=True)
    version = Column(String)
    doi = Column(String)
