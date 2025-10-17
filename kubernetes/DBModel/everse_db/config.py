"""
Module: config
Provides helpers to assemble database connection details from either a JSON file
or environment variables. This keeps secrets out of container images and git.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Dict, Optional


def load_config(file_path: Optional[str] = None) -> Dict[str, str]:
    """
    Load configuration from JSON when a path is supplied, otherwise fall back to env vars.

    Recognised environment variables:
        DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT

    Args:
        file_path: Optional path to a JSON file containing the same keys.
    """
    if file_path:
        config_path = Path(file_path)
        if not config_path.exists():
            raise FileNotFoundError(f"Database config file not found: {config_path}")
        with config_path.open("r", encoding="utf-8") as handle:
            config = json.load(handle)
    else:
        config = {
            "dbname": os.environ.get("DB_NAME", "superset"),
            "user": os.environ.get("DB_USER", "superset"),
            "password": os.environ.get("DB_PASSWORD", "superset"),
            "host": os.environ.get("DB_HOST", "0.0.0.0"),
            "port": int(os.environ.get("DB_PORT", 5432)),
        }

    config.setdefault("schema_name", os.environ.get("DB_SCHEMA", DEFAULT_SCHEMA_NAME))
    return config


def build_database_url(config: Dict[str, str]) -> str:
    """
    Construct a PostgreSQL database URL using configuration parameters.
    """
    dbname = config.get("dbname", "superset")
    user = config.get("user", "superset")
    password = config.get("password", "superset")
    host = config.get("host", "0.0.0.0")
    port = config.get("port", 5432)
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"


#: The default schema name used in the database.
DEFAULT_SCHEMA_NAME = "everse"
