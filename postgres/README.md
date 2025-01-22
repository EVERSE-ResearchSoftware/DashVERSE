# Database tools

This folder contains code to prepare and test the database. It contains SQL scripts to create a database schema and query data.

## Starting and stopping the database

To start run:

```shell
cd server
docker compose up
```

To stop run:

```shell
docker compose down --volumes --remove-orphans
```

## Connecting the database

Install the `postresql` package provided for your sytstem.

To connect to the PostgreSQL server run:

```shell
psql --username root --port 5432 --host 0.0.0.0 everse
```

## Adding the tables to the database

The SQL scripts to create the tables are in `schema` folder. These scripts will create the tables and columns alligned with the schemas defined in <https://github.com/EVERSE-ResearchSoftware/schemas> repository.

## Adding mock data

### Mock Data Generator for PostgreSQL Database

This Python script (populate_database.py) uses the `Faker` library to generate mock data and populate a PostgreSQL database. The script supports command-line arguments to customize the number of records generated for each table.

### Features

- Generates mock data for the following tables:
  - `organization`
  - `person`
  - `indicators`
- Reads database connection details from a JSON file (`db_config.json`).
- Supports command-line arguments to specify the number of records for each table.

### Prerequisites

- Python 3.7+
- PostgreSQL database
- Installed Python libraries:
  - `Faker`
  - `psycopg2`
  - `tabulate`

### Setup

#### 1. Install Required Libraries

Install the necessary Python libraries using pip:

```bash
pip install faker psycopg2 tabulate
```

#### 2. Prepare the Database

Ensure your PostgreSQL database has the schema as in `schema/db_schema_indicators.sql`.

#### 3. Create the Database Configuration File

Create a `db_config.json` file in the same directory as the script:

```json
{
  "dbname": "your_db",
  "user": "your_user",
  "password": "your_password",
  "host": "localhost",
  "port": 5432
}
```

Replace the placeholders with your database credentials.

### Usage

#### Running the Script

##### Command-Line Arguments

- `--organizations`: Number of records for the `organization` table (default: 10).
- `--people`: Number of records for the `person` table (default: 20).
- `--indicators`: Number of records for the `indicators` table (default: 50).

##### Example Commands

1. Use default values:

   ```bash
   python populate_database.py
   ```

2. Specify custom record counts:

   ```bash
   python populate_database.py --organizations 15 --people 30 --indicators 100
   ```

#### Output

The script will:

1. Populate the `organization` table with the specified number of records.
2. Populate the `person` table with random records linked to the organizations.
3. Populate the `indicators` table with random records linked to the people.

#### Logs

The script prints progress messages to the console, indicating the number of records inserted into each table.

### Example Output

```text
Populating organization table with 10 records...
Populating person table with 20 records...
Populating indicators table with 50 records...
Database populated successfully!
```

### Error Handling

- The script will roll back all changes if an error occurs.
- Ensure the database schema matches the requirements to avoid integrity constraint violations.
