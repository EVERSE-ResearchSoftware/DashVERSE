# Database Model

The DashVERSE data layer is deployed to the `everse` schema inside PostgreSQL and is designed around the JSON-LD structures defined in the EVERSE schemas repository.

## Core Tables

- `dimensions` – reference list of software quality dimensions (`identifier` is unique).
- `indicators` – quality indicators, tagged with keywords, release details, and linked dimensions.
- `software` – registered software artefacts and metadata.
- `assessments` – high-level metadata for a software quality assessment, including the JSON-LD `@context`, `@type`, descriptive text, timestamp, and licence.
- `assessment_creators` – people or organisations responsible for the assessment (`assessment_id` FK).
- `assessment_software` – the assessed software instance (`assessment_id` FK, one-to-one).
- `assessment_checks` – individual check results for each indicator assessed (`assessment_id` FK).
- `content_relation` – joins indicators, dimensions, and software records (used by existing dashboards).

All identifiers (`identifier` columns) are unique and indexed. Initial seed data for `dimensions` is safely idempotent.

## Populating Data Locally

The `kubernetes/DBModel/populate_data.py` script can initialise fake data for development. It consumes database credentials from environment variables or an optional JSON file (same keys).

```shell
cd kubernetes/DBModel
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=superset
export DB_USER=postgres
export DB_PASSWORD=secret
python populate_data.py --num_assessment 3
```

Command-line flags let you control the amount of generated data; use `--clear` to truncate all tables before exiting. The script reflects the production schema, creating assessments with nested creators, software details, and checks.

## Alignment with EVERSE JSON

Incoming JSON payloads should map to the `AssessmentModel` Pydantic schema:

- `@context`, `@type`, `name`, `description`, `dateCreated`, and `license` populate `assessments`.
- `creator` expands into `assessment_creators`.
- `assessedSoftware` becomes `assessment_software`.
- Each entry in `checks` creates a row in `assessment_checks`.

The PostgREST API exposes these tables individually. Create an assessment by inserting into `assessments` first, then POST child rows referencing the returned `assessment_id`. Retrieval supports embedding, for example:

```shell
curl -H "Authorization: Bearer $EVERSE_TOKEN" \
  'https://db.YOUR_DOMAIN/assessments?select=*,assessment_creators(*),assessment_software(*),assessment_checks(*)'
```

This returns a fully hydrated assessment document suitable for downstream analytics or Superset datasets.
