"""
Assessment data model and supporting Pydantic schemas.

The structures mirror the EVERSE JSON-LD specification so that incoming
assessment payloads can be validated and normalised before persisting them in
PostgreSQL. The relational layout favours analytical queries over nested JSON.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import AnyUrl, BaseModel as PydanticBaseModel, Field, validator
from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import relationship

from .base import Base

SCHEMA_NAME = "everse"


# ---------------------------------------------------------------------------
# Pydantic representations of the JSON-LD payloads used by the CLI ingestors.
# ---------------------------------------------------------------------------


class ReferenceModel(PydanticBaseModel):
    """Generic wrapper for JSON-LD references that only expose an @id."""

    id: AnyUrl = Field(alias="@id")


class CreatorModel(PydanticBaseModel):
    """Creator metadata for an assessment record."""

    type: Optional[str] = Field(default=None, alias="@type")
    name: str
    email: Optional[str] = None


class IdentifierModel(PydanticBaseModel):
    """Representation of schema:identifier blocks."""

    id: AnyUrl = Field(alias="@id")


class AssessedSoftwareModel(PydanticBaseModel):
    """Details of the assessed software artefact."""

    type: Optional[str] = Field(default=None, alias="@type")
    name: str
    softwareVersion: Optional[str] = None
    url: Optional[AnyUrl] = None
    identifier: Optional[IdentifierModel] = Field(
        default=None, alias="schema:identifier"
    )


class CheckingSoftwareModel(PydanticBaseModel):
    """Details describing the tool that produced a check result."""

    type: Optional[str] = Field(default=None, alias="@type")
    name: str
    id: Optional[AnyUrl] = Field(default=None, alias="@id")
    softwareVersion: Optional[str] = None


class CheckResultModel(PydanticBaseModel):
    """Result of an automated check run as part of the assessment."""

    type: Optional[str] = Field(default=None, alias="@type")
    assessesIndicator: ReferenceModel
    checkingSoftware: CheckingSoftwareModel
    process: Optional[str] = None
    status: ReferenceModel
    output: Optional[str] = None
    evidence: Optional[str] = None

    class Config:
        allow_population_by_field_name = True


class AssessmentModel(PydanticBaseModel):
    """Top level JSON-LD document describing an EVERSE assessment."""

    context: AnyUrl = Field(alias="@context")
    type: str = Field(alias="@type")
    name: str
    description: str
    creator: CreatorModel
    dateCreated: datetime
    license: ReferenceModel
    assessedSoftware: AssessedSoftwareModel
    checks: List[CheckResultModel] = Field(default_factory=list)

    @validator("checks", pre=True, always=True)
    def ensure_checks(cls, value):  # type: ignore[override]
        return value or []

    class Config:
        allow_population_by_field_name = True


# ---------------------------------------------------------------------------
# SQLAlchemy models
# ---------------------------------------------------------------------------


class Assessment(Base):
    """
    Core assessment record.

    Relationships:
        - creators (AssessmentCreator)
        - assessed_software (AssessmentSoftware)
        - checks (AssessmentCheck)
    """

    __tablename__ = "assessments"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    context = Column(String, nullable=False)
    type = Column(String, nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    date_created = Column(DateTime(timezone=True), nullable=False)
    license_uri = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    creators = relationship(
        "AssessmentCreator",
        back_populates="assessment",
        cascade="all, delete-orphan",
    )
    assessed_software = relationship(
        "AssessmentSoftware",
        back_populates="assessment",
        uselist=False,
        cascade="all, delete-orphan",
    )
    checks = relationship(
        "AssessmentCheck",
        back_populates="assessment",
        cascade="all, delete-orphan",
    )


class AssessmentCreator(Base):
    """Person or organisation responsible for the assessment."""

    __tablename__ = "assessment_creators"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    assessment_id = Column(
        Integer, ForeignKey(f"{SCHEMA_NAME}.assessments.id"), nullable=False
    )
    type = Column(String, nullable=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=True)

    assessment = relationship("Assessment", back_populates="creators")


class AssessmentSoftware(Base):
    """Software artefact that underwent assessment."""

    __tablename__ = "assessment_software"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    assessment_id = Column(
        Integer,
        ForeignKey(f"{SCHEMA_NAME}.assessments.id"),
        nullable=False,
        unique=True,
    )
    type = Column(String, nullable=True)
    name = Column(String, nullable=False)
    version = Column(String, nullable=True)
    url = Column(String, nullable=True)
    identifier_uri = Column(String, nullable=True)

    assessment = relationship("Assessment", back_populates="assessed_software")


class AssessmentCheck(Base):
    """Individual outcome for an indicator check."""

    __tablename__ = "assessment_checks"
    __table_args__ = {"schema": SCHEMA_NAME}

    id = Column(Integer, primary_key=True, autoincrement=True)
    assessment_id = Column(
        Integer, ForeignKey(f"{SCHEMA_NAME}.assessments.id"), nullable=False
    )
    type = Column(String, nullable=True)
    indicator_uri = Column(String, nullable=False)
    checking_software_type = Column(String, nullable=True)
    checking_software_name = Column(String, nullable=False)
    checking_software_uri = Column(String, nullable=True)
    checking_software_version = Column(String, nullable=True)
    process = Column(Text, nullable=True)
    status_uri = Column(String, nullable=False)
    output = Column(Text, nullable=True)
    evidence = Column(Text, nullable=True)

    assessment = relationship("Assessment", back_populates="checks")
