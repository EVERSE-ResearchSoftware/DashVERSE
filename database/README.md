# Database

PostgreSQL database for DashVERSE, including the schema, views, and seed data
used by PostgREST and Superset.

## Structure

- `everse_db/` -- SQLAlchemy models and configuration
- `sql/schema/` -- SQL files applied in numeric order during init
- `sql/data/` -- seed data loaded after schema creation
- `main.py` -- ORM-based database initialisation script
- `populate_data.py` -- generates mock data for testing

## Schema overview

Tables live in the `api` schema so PostgREST can expose them directly.
The `auth` schema is reserved for authentication tables.
