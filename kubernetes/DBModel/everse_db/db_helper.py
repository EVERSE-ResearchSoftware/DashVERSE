"""
Module: db_helper
Provides the EverseDB helper class for initializing the database schema, creating tables,
and querying table metadata.
"""

from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker
from .config import DEFAULT_SCHEMA_NAME
from .models.base import Base
from sqlalchemy.engine.url import make_url


class EverseDB:
    """
    Helper class to manage database initialization and inspection.

    Attributes:
        database_url (str): The PostgreSQL connection string.
        schema (str): The database schema to use.
        engine: The SQLAlchemy engine instance.
        SessionLocal: A configured SQLAlchemy sessionmaker.
    """

    def __init__(self, database_url: str, schema: str = DEFAULT_SCHEMA_NAME):
        """
        Initialize the EverseDB helper with the provided database URL and schema.

        Args:
            database_url (str): The PostgreSQL connection URL.
            schema (str, optional): The database schema name. Defaults to DEFAULT_SCHEMA_NAME.
        """
        self.database_url = database_url
        self.schema = schema
        self.engine = create_engine(self.database_url)
        self.SessionLocal = sessionmaker(
            autocommit=False, autoflush=False, bind=self.engine
        )

    def init_db(self) -> None:
        """
        Initialize the database by creating the schema (if it doesn't exist)
        and all tables defined in the metadata.
        Also prints connection details (excluding sensitive information).
        """
        # Create schema if it doesn't exist.
        with self.engine.connect() as connection:
            connection.execute(text(f"CREATE SCHEMA IF NOT EXISTS {self.schema}"))
            connection.commit()
        # Create all tables.
        Base.metadata.create_all(self.engine)

        # Parse database URL to extract non‑sensitive details.
        url_obj = make_url(self.database_url)
        host = url_obj.host
        port = url_obj.port
        database = url_obj.database
        username = url_obj.username

        print(f"Database initialized with schema '{self.schema}'.")
        print(
            f"Connected to server at {host}:{port} and database '{database}' as user '{username}'."
        )

    def query_tables_and_columns(self) -> dict:
        """
        Query the database to retrieve table names and their columns.

        Returns:
            dict: A dictionary where keys are table names and values are lists of column info dictionaries.
        """
        inspector = inspect(self.engine)
        table_names = inspector.get_table_names(schema=self.schema)
        tables_info = {}
        for table in table_names:
            columns = inspector.get_columns(table, schema=self.schema)
            tables_info[table] = columns
        return tables_info

    def print_tables_and_columns(self) -> None:
        """
        Print the tables and their column details (including column types) for the schema.
        """
        tables_info = self.query_tables_and_columns()
        print(f"Tables in schema '{self.schema}':")
        for table, columns in tables_info.items():
            print(f"\nTable: {table}")
            for column in columns:
                print(f"  - Column: {column['name']} (Type: {column['type']})")
