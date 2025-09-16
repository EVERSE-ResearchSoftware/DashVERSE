"""
Module: models/assessment
Contains the Assessment domain model which records various checks performed by external tools.
The check result can be of various data types and is stored in a JSONB column.
Each assessment record is related to a Software entry.
"""

from datetime import datetime
from typing import Any, Optional, List, Union
from pydantic import BaseModel as PydanticBaseModel
from pydantic import AnyUrl, Field

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB, ARRAY
from .base import Base


SCHEMA_NAME = "everse"


# class AssessmentModel_OLD(PydanticBaseModel):
#     """
#     Pydantic model for validating Assessment data.

#     Attributes:
#         id (Optional[int]): Unique identifier for the assessment record.
#         software_id (int): Foreign key referencing the related Software record.
#         check_name (str): The name or type of the check performed.
#         tool (str): The external tool that performed the check.
#         result (Any): The result of the check, which can be of various data types.
#         timestamp (Optional[datetime]): The time when the check was performed.
#     """

#     id: Optional[int] = None
#     software_id: int
#     check_name: str
#     tool: str
#     result: Any
#     timestamp: Optional[datetime] = None


# class Assessment_OLD(Base):
#     """
#     SQLAlchemy model for Assessment.

#     Records various checks done by external tools. The check result is stored in a JSONB column,
#     allowing for multiple data types (e.g., boolean, numerical, string). Each record is related to a Software entry.
#     """

#     __tablename__ = "assessment"
#     __table_args__ = {"schema": SCHEMA_NAME}

#     id = Column(Integer, primary_key=True, autoincrement=True)
#     software_id = Column(
#         Integer, ForeignKey(f"{SCHEMA_NAME}.software.id"), nullable=False
#     )
#     check_name = Column(String, nullable=False)
#     tool = Column(String, nullable=False)
#     result = Column(JSONB)
#     timestamp = Column(DateTime, nullable=True, default=datetime.utcnow)



class AssessedSoftwareItem(PydanticBaseModel):
    name: List[str]
    identifier: List[AnyUrl]

class CheckResultItem(PydanticBaseModel):
    assessesIndicator: List[AnyUrl] = Field(alias='rsqa_assessesIndicator')
    checkingSoftware: List[AnyUrl] = Field(alias='rsqa_checkingSoftware')
    checkEvidence: List[str] = Field(alias='rsqa_checkEvidence')
    checkOutput: List[str] = Field(alias='rsqa_checkOutput')
    actionProcess: List[AnyUrl]
    actionStatus: List[AnyUrl]

class CreatorItem(PydanticBaseModel):
    name: List[str]

class AssessmentModel(PydanticBaseModel):

    field_context: AnyUrl = Field(alias='@context', description='The JSON-LD context for the document.')
    field_type: Union[AnyUrl, List[AnyUrl]] = Field(alias='@type', description='The type(s) of the resource (IRI or array of IRIs).')
    assessedSoftware: List[AssessedSoftwareItem] = Field(alias='rsqa_assessedSoftware')
    CheckResult: List[CheckResultItem] = Field(alias='rsqa_CheckResult')
    creator: List[CreatorItem]
    dateCreated: List[str]
    description: List[str]
    license: List[AnyUrl]
    name: List[str]

class Assessment(Base):
    __tablename__ = "assessment"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    creator = Column(ARRAY(JSONB), nullable=False)
    dateCreated = Column(DateTime, nullable=False)
    license = Column(JSONB, nullable=False)

    assessedSoftware = Column(JSONB, nullable=False)

    checks = Column(ARRAY(JSONB), nullable=False)
