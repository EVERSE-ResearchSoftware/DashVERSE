# SQL Script Executor

[execute_sql.py](scripts/execute_sql.py) script allows you to execute SQL scripts on a PostgreSQL database. It supports features such as displaying query results in a table format and saving them to a JSON file. The script also reports the success or failure of the SQL execution.

## Features

- Execute SQL scripts from a file.
- Display query results in a well-formatted table.
- Save query results to a JSON file.
- Handle multiple SQL statements within a single file.
- Report the success or failure of the SQL execution.
- Truncate long text fields for better readability in terminal output.

## Prerequisites

- Python 3.7+
- PostgreSQL database
- Installed Python libraries:
  - `psycopg2`
  - `tabulate`

## Setup

### 1. Install Required Libraries

Install the necessary Python libraries using pip:

```bash
pip install psycopg2 tabulate
```

### 2. Prepare the Database Configuration File

Create a `db_config.json` file in the same directory as the script with the following structure:

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

### 3. Create an SQL File

Prepare an SQL file (e.g., `db_retrieve_indicators.sql`) containing your SQL commands. This file can include multiple SQL statements separated by semicolons (`;`). For example:

```sql
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO test_table (name) VALUES ('Sample Name');

SELECT * FROM test_table;
```

## Usage

### Command-Line Arguments

- `--sql-file`: Path to the SQL file to execute. Default is `db_retrieve_indicators.sql`.
- `--max-length`: Maximum number of characters to display for long text fields. Default is `50`.
- `--save-json`: Save query results to a JSON file (`output.json`).
- `--display-table`: Display query results in a table format in the terminal.

### Example Commands

#### Run with Default Settings

```bash
python execute_sql.py
```

#### Specify a Custom SQL File

```bash
python execute_sql.py --sql-file custom_queries.sql
```

#### Display Query Results as a Table

```bash
python execute_sql.py --display-table
```

#### Save Query Results to JSON

```bash
python execute_sql.py --save-json
```

#### Display Results and Save to JSON

```bash
python execute_sql.py --display-table --save-json
```

## Output

### Terminal Output (Table Format)

If `--display-table` is used, the query results will be displayed in a tabular format:

```text
Query Results (Table Format):

+----+----------------+
| id | name           |
+----+----------------+
|  1 | Sample Name    |
+----+----------------+
```

### JSON File Output

If `--save-json` is used, the query results will be saved to a JSON file named `output.json`. Example:

```json
[
    {
        "id": 1,
        "name": "Sample Name"
    }
]
```

## Error Handling

- The script will report any errors during execution and roll back the transaction if needed.
- Examples of errors include:
  - Missing SQL file.
  - Syntax errors in the SQL script.
  - Database connection issues.
