"""
Module: models/base
Provides the common SQLAlchemy Base instance for all models.
"""

from sqlalchemy.ext.declarative import declarative_base

#: The base class for all SQLAlchemy models in the package.
Base = declarative_base()
