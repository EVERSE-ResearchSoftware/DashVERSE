import json
import argparse
import psycopg2
from psycopg2.extras import DictCursor
from tabulate import tabulate
from datetime import date


# Custom JSON encoder for handling non-serializable objects
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, date):
            return obj.isoformat()  # Convert date to ISO format string
        return super().default(obj)


# Load database connection details from a JSON file
def load_db_config(file_path):
    with open(file_path, "r") as file:
        return json.load(file)


# Load the entire SQL file as a single text value
def load_sql_file(file_path):
    try:
        with open(file_path, "r") as file:
            return file.read()
    except FileNotFoundError:
        print(f"Error: SQL file '{file_path}' not found.")
        exit(1)


# Save results to a JSON file
def save_to_json_file(data, output_file):
    with open(output_file, "w") as file:
        json.dump(data, file, indent=4, cls=CustomJSONEncoder)


# Truncate long text fields to a specified length
def truncate_long_text(row, max_length=50):
    return {
        key: (
            value[:max_length] + "..."
            if isinstance(value, str) and len(value) > max_length
            else value
        )
        for key, value in row.items()
    }


# Execute the SQL script and handle results
def execute_sql_script(sql_script, db_config, max_length, save_json, display_table):
    success = False  # Track success status
    try:
        # Connect to the database
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor(cursor_factory=DictCursor)

        # Execute the SQL script
        print(f"Executing SQL script from file...")
        cursor.execute(sql_script)

        # Fetch results if the SQL script includes a SELECT statement
        if "select" in sql_script.lower():
            results = cursor.fetchall()
            results_dict = [
                truncate_long_text(dict(row), max_length=max_length) for row in results
            ]

            # Display the results as a table
            if display_table:
                if results_dict:
                    print("\nQuery Results (Table Format):")
                    headers = results_dict[0].keys()
                    rows = [list(row.values()) for row in results_dict]
                    print(tabulate(rows, headers=headers, tablefmt="grid"))
                else:
                    print("\nNo data found in the database.")

            # Save the results to a JSON file
            if save_json:
                save_to_json_file(results_dict, "output.json")
                print("\nResults have been saved to 'output.json'.")

        # Commit the transaction and set success to True
        conn.commit()
        success = True

    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()  # Rollback transaction on error

    finally:
        # Close the connection
        if cursor:
            cursor.close()
        if conn:
            conn.close()

    # Report success or failure
    if success:
        print("\nSQL script executed successfully.")
    else:
        print("\nSQL script execution failed.")


if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description="Execute an SQL script on a PostgreSQL database."
    )
    parser.add_argument(
        "--db-file",
        type=str,
        default="db_config.json",
        help="Path to the JSON file containing the database credentials (default: db_config.json).",
    )
    parser.add_argument(
        "--sql-file",
        type=str,
        default="db_retrieve_indicators.sql",
        help="Path to the SQL file containing the queries (default: db_retrieve_indicators.sql).",
    )
    parser.add_argument(
        "--max-length",
        type=int,
        default=50,
        help="Maximum number of characters to display for long text fields (default: 50).",
    )
    parser.add_argument(
        "--save-json",
        action="store_true",
        help="Save the query results to a JSON file.",
    )
    parser.add_argument(
        "--display-table",
        action="store_true",
        help="Display the query results in a table format.",
    )
    args = parser.parse_args()

    # Load database configuration
    db_config = load_db_config(args.db_file)

    # Load the SQL script as a single text value
    sql_script = load_sql_file(args.sql_file)

    # Execute the SQL script
    execute_sql_script(
        sql_script, db_config, args.max_length, args.save_json, args.display_table
    )
