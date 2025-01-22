import json
import argparse
from faker import Faker
import psycopg2
import random

# Initialize Faker
fake = Faker()

# Load database connection details from a JSON file
def load_db_config(file_path):
    with open(file_path, "r") as file:
        return json.load(file)

# Insert data into the 'organization' table
def populate_organization(cursor, num_records=10):
    organizations = []
    for _ in range(num_records):
        name = fake.company()
        url = fake.url()
        image_url = fake.image_url()
        cursor.execute(
            """
            INSERT INTO organization (name, url, "image-url")
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (name, url, image_url),
        )
        organizations.append(cursor.fetchone()[0])
    return organizations

# Insert data into the 'person' table
def populate_person(cursor, organizations, num_records=20):
    people = []
    for _ in range(num_records):
        name = fake.name()
        orcid = fake.uuid4()
        github = fake.url()
        gitlab = fake.url()
        email = fake.email()
        affiliation = fake.company()
        image_url = fake.image_url()
        organization_id = random.choice(organizations) if organizations else None
        cursor.execute(
            """
            INSERT INTO person (name, orcid, github, gitlab, email, affiliation, "image-url", organization_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (name, orcid, github, gitlab, email, affiliation, image_url, organization_id),
        )
        people.append(cursor.fetchone()[0])
    return people

# Insert data into the 'indicators' table
def populate_indicators(cursor, authors, contacts, num_records=50):
    keywords_options = ['keyword-1', 'keyword-2', 'keyword-3']
    status_options = ['active', 'deprecated']
    quality_dimensions = ['openness', 'FAIRness', 'sustainability']
    for _ in range(num_records):
        identifier = fake.uuid4()
        name = fake.sentence(nb_words=4)
        description = fake.text(max_nb_chars=200)
        keywords = random.choice(keywords_options)
        status = random.choice(status_options)
        quality_dimension = random.choice(quality_dimensions)
        release_date = fake.date_this_decade()
        version = f"{random.randint(1, 10)}.{random.randint(0, 9)}"
        doi = fake.url()
        authors_id = random.choice(authors) if authors else None
        contacts_id = random.choice(contacts) if contacts else None
        cursor.execute(
            """
            INSERT INTO indicators (
                identifier, name, description, keywords, status, "quality-dimension",
                "release-date", version, doi, authors_id, contacts_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                identifier, name, description, keywords, status, quality_dimension,
                release_date, version, doi, authors_id, contacts_id,
            ),
        )

# Main function to populate all tables
def main(num_records):
    try:
        # Load database config
        db_config = load_db_config("db_config.json")

        # Connect to the database
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()

        print(f"Populating organization table with {num_records['organizations']} records...")
        organizations = populate_organization(cursor, num_records['organizations'])

        print(f"Populating person table with {num_records['people']} records...")
        people = populate_person(cursor, organizations, num_records['people'])

        print(f"Populating indicators table with {num_records['indicators']} records...")
        populate_indicators(cursor, people, people, num_records['indicators'])

        # Commit changes
        conn.commit()
        print("Database populated successfully!")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Populate a PostgreSQL database with mock data.")
    parser.add_argument("--organizations", type=int, default=10, help="Number of organization records to generate.")
    parser.add_argument("--people", type=int, default=20, help="Number of person records to generate.")
    parser.add_argument("--indicators", type=int, default=50, help="Number of indicator records to generate.")
    args = parser.parse_args()

    # Pass the parsed arguments to the main function
    main({
        "organizations": args.organizations,
        "people": args.people,
        "indicators": args.indicators,
    })
