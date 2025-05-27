"""
Main script to initialize the database.
Reads database configuration from a JSON file provided via a command-line argument,
builds the connection string, and initializes the database schema and tables.
"""

import argparse
from everse_db.config import load_config, build_database_url, DEFAULT_SCHEMA_NAME
from everse_db.db_helper import EverseDB


def main():
    """
    Parse command-line arguments to load the database configuration,
    initialize the database, and print the table metadata.
    """
    parser = argparse.ArgumentParser(
        description="Initialize the database using a JSON config file."
    )
    parser.add_argument("--config", help="Path to JSON config file", required=True)
    args = parser.parse_args()

    # Load configuration from the JSON file.
    config = load_config(args.config)
    # Build the database URL from the configuration.
    database_url = build_database_url(config)
    # Use the provided schema name if available; otherwise, use the default.
    schema_name = config.get("schema_name", DEFAULT_SCHEMA_NAME)

    db = EverseDB(database_url=database_url, schema=schema_name)
    db.init_db()
    db.print_tables_and_columns()


if __name__ == "__main__":
    main()
