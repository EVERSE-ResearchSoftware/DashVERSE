"""
populate_data.py

This script populates the database with mock (fake) data for each model.
Connection information is sourced from environment variables or an optional JSON
configuration file, mirroring the runtime behaviour of the init job.

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
from datetime import datetime, timezone
from faker import Faker
from tabulate import tabulate
from sqlalchemy import text

# Import configuration and database helper
from everse_db.config import load_config, build_database_url, DEFAULT_SCHEMA_NAME
from everse_db.db_helper import EverseDB

# Import models
from everse_db.models.indicator import Indicator
from everse_db.models.dimension import Dimension
from everse_db.models.software import Software
from everse_db.models.assessment import (
    Assessment,
    AssessmentCheck,
    AssessmentCreator,
    AssessmentSoftware,
)
from everse_db.models.content_relation import ContentRelation

# Initialize Faker instance
fake = Faker()

def create_fake_indicator(idx: int) -> Indicator:
    """Create a fake Indicator instance."""
    indicator = Indicator(
        identifier=f"IND-{idx:03d}",
        name=fake.sentence(nb_words=3).rstrip('.'),
        description=fake.text(max_nb_chars=100),
        status=random.choice(["Active", "Deprecated"]),
        quality_dimension=f"DIM-{random.randint(1, 5):03d}",
        contact={"name": fake.name(), "email": fake.email()},
        source={"url": fake.url(), "name": fake.company()}
    )
    return indicator

def create_fake_dimension(idx: int) -> Dimension:
    """Create a fake Dimension instance."""
    dimension = Dimension(
        identifier=f"DIM-{idx:03d}",
        name=fake.sentence(nb_words=2).rstrip('.'),
        description=fake.text(max_nb_chars=80),
        status=random.choice(["Active", "Deprecated"]),
        source={"url": fake.url(), "reference": fake.word()}
    )
    return dimension

def create_fake_software(idx: int) -> Software:
    """Create a fake Software instance."""
    langs = ["Python", "JavaScript", "Go", "Rust", "Java", "C++"]
    software = Software(
        identifier=f"SW-{idx:03d}",
        name=fake.company(),
        description=fake.text(max_nb_chars=100),
        version=f"{random.randint(0, 3)}.{random.randint(0, 9)}.{random.randint(0, 9)}",
        license=random.choice(["MIT", "GPL-3.0", "Apache-2.0", "BSD-3-Clause"]),
        repository_url=f"https://github.com/{fake.user_name()}/{fake.slug()}",
        homepage_url=fake.url(),
        programming_language=random.sample(langs, random.randint(1, 3))
    )
    return software

def create_fake_assessment(idx: int) -> Assessment:
    """
    Create a fake Assessment SQLAlchemy model instance aligned with the EVERSE schema.

    Args:
        idx (int): Index used for reference.

    Returns:
        Assessment: A new Assessment instance with fake nested records.
    """
    assessment = Assessment(
        context="https://w3id.org/everse/rsqa/0.0.1/",
        type="SoftwareQualityAssessment",
        name=f"Quality Assessment #{idx}",
        description=fake.paragraph(nb_sentences=3),
        date_created=fake.date_time_this_year(tzinfo=timezone.utc),
        license_uri=f"https://example.org/license/{idx}",
    )

    creator = AssessmentCreator(
        type="schema:Person",
        name=fake.name(),
        email=fake.email(),
    )
    assessment.creators.append(creator)

    software = AssessmentSoftware(
        type="schema:SoftwareApplication",
        name=fake.company(),
        version=f"{random.randint(0, 3)}.{random.randint(0, 9)}.{random.randint(0, 9)}",
        url=fake.url(),
        identifier_uri=f"https://doi.org/10.1234/{fake.lexify(text='?????')}",
    )
    assessment.assessed_software = software

    for _ in range(random.randint(1, 4)):
        indicator_uri = f"https://w3id.org/everse/i/indicators/{fake.slug()}"
        check = AssessmentCheck(
            type="CheckResult",
            indicator_uri=indicator_uri,
            checking_software_type="schema:SoftwareApplication",
            checking_software_name=fake.word(),
            checking_software_uri=f"https://w3id.org/everse/tools/{fake.slug()}",
            checking_software_version=fake.numerify(text="0.##"),
            process=fake.sentence(nb_words=8),
            status_uri="schema:CompletedActionStatus",
            output=random.choice(["true", "valid", "false"]),
            evidence=fake.text(max_nb_chars=120),
        )
        assessment.checks.append(check)

    return assessment

def create_fake_content_relation(indicator_ids: list, dimension_ids: list, software_ids: list) -> ContentRelation:
    """
    Create a fake ContentRelation by randomly linking existing records.
    """
    relation = ContentRelation(
        indicator_id=random.choice(indicator_ids),
        dimension_id=random.choice(dimension_ids),
        software_id=random.choice(software_ids)
    )
    return relation

def print_entries(session, model, title: str) -> None:
    """
    Query and print all entries for a given model in a formatted table.
    """
    entries = session.query(model).all()
    if not entries:
        print(f"\n=== {title} (No entries found) ===")
        return

    data = []
    if model is Assessment:
        for entry in entries:
            row = {
                "id": entry.id,
                "name": entry.name,
                "checks": len(entry.checks),
                "creator": ", ".join(c.name for c in entry.creators),
                "software": entry.assessed_software.name if entry.assessed_software else None,
            }
            data.append(row)
    else:
        for entry in entries:
            row = {k: v for k, v in entry.__dict__.items() if not k.startswith("_")}
            data.append(row)

    print(f"\n=== {title} ({len(entries)} entries) ===")
    print(tabulate(data, headers="keys", tablefmt="pretty"))

def clear_existing_entries(session, schema: str) -> None:
    """
    Remove all existing entries from all tables using TRUNCATE ... CASCADE.
    """
    truncate_query = text(f"""
        TRUNCATE TABLE {schema}.content_relation,
                       {schema}.assessment_checks,
                       {schema}.assessment_software,
                       {schema}.assessment_creators,
                       {schema}.assessments,
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
    Main function to parse arguments, optionally clear existing data,
    generate fake data, insert it, and print the results.
    """
    parser = argparse.ArgumentParser(
        description="Populate the database with mock data using environment variables or an optional JSON config file."
    )
    parser.add_argument(
        "--config",
        help="Path to JSON config file (optional). Overrides environment variables when supplied.",
        required=False,
    )
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
                assessment = create_fake_assessment(i)
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
