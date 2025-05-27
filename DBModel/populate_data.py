"""
populate_data.py

This script populates the database with mock (fake) data for each model.
It reads the database configuration from a JSON file (db_config.json) and uses command-line
arguments to specify the number of entries to create for each model.

Models populated:
  - Indicator
  - Dimension
  - Software
  - Assessment
  - ContentRelation (relations among Indicator, Dimension, and Software)

An optional command-line argument (--clear) will remove all existing entries from all tables
and then exit without adding new entries.

After insertion (or clearing), the script queries and prints the entries in a formatted table.
"""

import argparse
import random
from datetime import datetime
from faker import Faker
from tabulate import tabulate
from sqlalchemy import text

# Import configuration and database helper
from everse_db.config import load_config, build_database_url, DEFAULT_SCHEMA_NAME
from everse_db.db_helper import EverseDB

# Import models
from everse_db.models.indicator import Indicator, KeywordEnum, StatusEnum, QualityDimensionEnum
from everse_db.models.dimension import Dimension
from everse_db.models.software import Software, HowToUseEnum, QualityDimensionEnum as SWQualityDimensionEnum
from everse_db.models.assessment import Assessment
from everse_db.models.content_relation import ContentRelation

# Initialize Faker instance
fake = Faker()

def create_fake_indicator(idx: int) -> Indicator:
    """
    Create a fake Indicator SQLAlchemy model instance.

    Args:
        idx (int): Index used to generate a unique identifier.

    Returns:
        Indicator: A new Indicator instance with fake data.
    """
    indicator = Indicator(
        identifier=f"IND-{idx:03d}",
        name=fake.sentence(nb_words=3),
        description=fake.text(max_nb_chars=100),
        keywords=[random.choice(list(KeywordEnum)).value for _ in range(random.randint(1, 3))],
        status=random.choice(list(StatusEnum)),
        qualityDimensions=[random.choice(list(QualityDimensionEnum)).value for _ in range(random.randint(1, 2))],
        releaseDate=fake.date_time_this_decade(),
        version="1.0",
        doi=f"10.1234/{fake.lexify(text='?????')}"
    )
    return indicator

def create_fake_dimension(idx: int) -> Dimension:
    """
    Create a fake Dimension SQLAlchemy model instance.

    Args:
        idx (int): Index used to generate a unique identifier.

    Returns:
        Dimension: A new Dimension instance with fake data.
    """
    dimension = Dimension(
        identifier=f"DIM-{idx:03d}",
        name=fake.sentence(nb_words=2),
        description=fake.text(max_nb_chars=80),
        source=[fake.word() for _ in range(random.randint(1, 3))]
    )
    return dimension

def create_fake_software(idx: int) -> Software:
    """
    Create a fake Software SQLAlchemy model instance.

    Args:
        idx (int): Index used to generate a unique identifier.

    Returns:
        Software: A new Software instance with fake data.
    """
    software = Software(
        identifier=f"SW-{idx:03d}",
        name=fake.company(),
        description=fake.text(max_nb_chars=100),
        url=fake.url(),
        isAccessibleForFree=random.choice([True, False]),
        qualityDimensions=[random.choice(list(SWQualityDimensionEnum)).value for _ in range(random.randint(1, 3))],
        howToUse=[random.choice(list(HowToUseEnum)).value for _ in range(random.randint(1, 2))],
        license=random.choice(["MIT", "GPL", "Apache-2.0"])
    )
    return software

def create_fake_assessment(software_ids: list, idx: int) -> Assessment:
    """
    Create a fake Assessment SQLAlchemy model instance.

    Args:
        software_ids (list): List of available Software IDs.
        idx (int): Index used for reference.

    Returns:
        Assessment: A new Assessment instance with fake data.
    """
    # Randomly choose a result type: boolean, numeric, or string.
    r = random.random()
    if r < 0.33:
        result = random.choice([True, False])
    elif r < 0.66:
        result = round(random.uniform(0, 100), 2)
    else:
        result = fake.sentence(nb_words=4)

    assessment = Assessment(
        software_id=random.choice(software_ids),
        check_name=fake.word(),
        tool=fake.word(),
        result=result,
        timestamp=fake.date_time_this_year()
    )
    return assessment

def create_fake_content_relation(indicator_ids: list, dimension_ids: list, software_ids: list) -> ContentRelation:
    """
    Create a fake ContentRelation SQLAlchemy model instance by randomly linking existing records.

    Args:
        indicator_ids (list): List of available Indicator IDs.
        dimension_ids (list): List of available Dimension IDs.
        software_ids (list): List of available Software IDs.

    Returns:
        ContentRelation: A new ContentRelation instance linking the provided IDs.
    """
    relation = ContentRelation(
        indicator_id=random.choice(indicator_ids),
        dimension_id=random.choice(dimension_ids),
        software_id=random.choice(software_ids)
    )
    return relation

def print_entries(session, model, title: str) -> None:
    """
    Query and print all entries for a given model in a nicely formatted table.

    Args:
        session: SQLAlchemy session.
        model: The SQLAlchemy model class to query.
        title (str): Title to display for the entries.
    """
    entries = session.query(model).all()
    if not entries:
        print(f"\n=== {title} (No entries found) ===")
        return

    # Create a list of dictionaries for each entry, filtering out internal attributes.
    data = []
    for entry in entries:
        row = {k: v for k, v in entry.__dict__.items() if not k.startswith('_')}
        data.append(row)

    print(f"\n=== {title} ({len(entries)} entries) ===")
    print(tabulate(data, headers="keys", tablefmt="pretty"))

def clear_existing_entries(session, schema: str) -> None:
    """
    Remove all existing entries from all tables in the database using TRUNCATE ... CASCADE.

    Args:
        session: SQLAlchemy session.
        schema (str): The schema name to clear.
    """
    truncate_query = text(f"""
        TRUNCATE TABLE {schema}.content_relation,
                       {schema}.assessment,
                       {schema}.indicators,
                       {schema}.dimensions,
                       {schema}.software
        RESTART IDENTITY CASCADE;
    """)
    session.execute(truncate_query)
    session.commit()
    print("All existing entries have been cleared from the database.")

def main():
    """
    Main function to parse command-line arguments, optionally clear existing data,
    generate fake data, insert it into the database, and print out the added entries in a formatted table.

    If the --clear flag is used, the script will only clear the data and not add any new entries.
    """
    parser = argparse.ArgumentParser(
        description="Populate the database with mock data using the provided db_config.json."
    )
    parser.add_argument("--config", help="Path to JSON config file", required=True)
    parser.add_argument("--num_indicator", type=int, default=5, help="Number of Indicator entries to create")
    parser.add_argument("--num_dimension", type=int, default=5, help="Number of Dimension entries to create")
    parser.add_argument("--num_software", type=int, default=5, help="Number of Software entries to create")
    parser.add_argument("--num_assessment", type=int, default=5, help="Number of Assessment entries to create")
    parser.add_argument("--num_content_relation", type=int, default=5, help="Number of ContentRelation entries to create")
    parser.add_argument("--clear", action="store_true", help="Clear all existing entries in all tables and do not add new data")
    args = parser.parse_args()

    # Load configuration and build database URL.
    config = load_config(args.config)
    database_url = build_database_url(config)
    schema_name = config.get("schema_name", DEFAULT_SCHEMA_NAME)

    # Initialize database.
    db = EverseDB(database_url=database_url, schema=schema_name)
    db.init_db()
    session = db.SessionLocal()

    try:
        if args.clear:
            clear_existing_entries(session, schema_name)
            print("Database has been cleared. No new entries were added.")
        else:
            # Create Indicator entries.
            for i in range(1, args.num_indicator + 1):
                indicator = create_fake_indicator(i)
                session.add(indicator)
            session.commit()

            # Create Dimension entries.
            for i in range(1, args.num_dimension + 1):
                dimension = create_fake_dimension(i)
                session.add(dimension)
            session.commit()

            # Create Software entries.
            for i in range(1, args.num_software + 1):
                software = create_fake_software(i)
                session.add(software)
            session.commit()

            # Query generated primary keys for foreign key relationships.
            indicator_ids = [ind.id for ind in session.query(Indicator).all()]
            dimension_ids = [dim.id for dim in session.query(Dimension).all()]
            software_ids = [sw.id for sw in session.query(Software).all()]

            # Create Assessment entries.
            for i in range(1, args.num_assessment + 1):
                assessment = create_fake_assessment(software_ids, i)
                session.add(assessment)
            session.commit()

            # Create ContentRelation entries.
            for i in range(1, args.num_content_relation + 1):
                content_relation = create_fake_content_relation(indicator_ids, dimension_ids, software_ids)
                session.add(content_relation)
            session.commit()

        # Display added entries for each model.
        print_entries(session, Indicator, "Indicators")
        print_entries(session, Dimension, "Dimensions")
        print_entries(session, Software, "Software")
        print_entries(session, Assessment, "Assessments")
        print_entries(session, ContentRelation, "Content Relations")

    except Exception as e:
        session.rollback()
        print("Error occurred:", e)
    finally:
        session.close()

if __name__ == "__main__":
    main()
