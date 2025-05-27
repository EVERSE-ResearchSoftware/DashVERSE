"""
Module: config
Provides functions to load the database configuration from a JSON file and to build the PostgreSQL connection URL.
"""

import json


def load_config(file_path: str) -> dict:
    """
    Load and return the configuration dictionary from a JSON file.

    Args:
        file_path (str): The path to the JSON configuration file.

    Returns:
        dict: The configuration parameters loaded from the file.
    """
    with open(file_path, "r") as f:
        config = json.load(f)
    return config


def build_database_url(config: dict) -> str:
    """
    Construct and return a PostgreSQL database URL using configuration parameters.

    Expected keys in config:
        - "dbname": The name of the database.
        - "user": The username.
        - "password": The password.
        - "host": The host address.
        - "port": The port number.

    Args:
        config (dict): The configuration dictionary.

    Returns:
        str: A PostgreSQL connection URL.
    """
    dbname = config.get("dbname", "superset")
    user = config.get("user", "superset")
    password = config.get("password", "superset")
    host = config.get("host", "0.0.0.0")
    port = config.get("port", 5432)
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"


#: The default schema name used in the database.
DEFAULT_SCHEMA_NAME = "everse"
