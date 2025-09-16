"""
Module: models/software
Contains the Software domain model, including its enums, Pydantic model for validation,
and SQLAlchemy model for persistence.
"""

from enum import Enum
from typing import List, Optional
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy import Column, String, Integer, Boolean
from sqlalchemy.dialects.postgresql import ARRAY
from .base import Base

# --- Enums used by Software ---


class QualityDimensionEnum(str, Enum):
    """
    Enumeration for quality dimensions specific to Software.
    """

    openness = "openness"
    FAIRness = "FAIRness"
    sustainability = "sustainability"


class HowToUseEnum(str, Enum):
    """
    Enumeration for methods of using the software.
    """

    cicd = "CI/CD"
    cmdline = "command-line"


# --- Pydantic model for Software ---


class SoftwareModel(PydanticBaseModel):
    """
    Pydantic model for validating Software data.

    Attributes:
        id (Optional[int]): Unique identifier.
        identifier (str): A unique code for the software.
        name (str): The name of the software.
        description (str): A description of the software.
        url (str): URL for more information.
        isAccessibleForFree (bool): Whether the software is free to access.
        qualityDimensions (Optional[List[QualityDimensionEnum]]): Quality dimensions.
        howToUse (Optional[List[HowToUseEnum]]): Methods of use.
        license (str): Licensing information.
    """

    id: Optional[int] = None
    identifier: str
    name: str
    description: str
    url: str
    isAccessibleForFree: bool
    qualityDimensions: Optional[List[QualityDimensionEnum]] = None
    howToUse: Optional[List[HowToUseEnum]] = None
    license: str


SCHEMA_NAME = "everse"


class Software(Base):
    """
    SQLAlchemy model for the Software.

    Attributes correspond to columns in the 'software' table.
    """

    __tablename__ = "software"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    identifier = Column(String, nullable=False, index=True)
    name = Column(String)
    description = Column(String)
    url = Column(String)
    isAccessibleForFree = Column(Boolean)
    qualityDimensions = Column(ARRAY(String))
    howToUse = Column(ARRAY(String))
    license = Column(String)
