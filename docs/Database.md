# Database Schema

The DashVERSE database uses PostgreSQL with the `api` schema, designed for compatibility with resqui and PostgREST.

## Overview

DashVERSE stores research software quality assessment data following the EVERSE (European Virtual Institute for Research Software Excellence) framework aligned with ISO/IEC 25010 software quality standards. The database captures:

- Research software metadata (name, license, repository, languages)
- Quality dimensions (categories like Testing, Documentation, Security)
- Quality indicators (specific measurable criteria within dimensions)
- Assessment results with individual check outcomes

## Core Tables

| Table | Description |
|-------|-------------|
| `software` | Registered software with metadata |
| `dimensions` | Quality dimensions (e.g., Testing, Documentation) |
| `indicators` | Quality indicators linked to dimensions |
| `assessment_raw` | Raw assessment data stored as JSONB |

### software (view, derived)

`software` is a **view** over `assessment_raw`, not a base table. Every
column is sourced from the rsqa payload's `assessedSoftware` block; no
hand-curated per-deployment metadata is exposed.

| Column | Source |
|--------|--------|
| identifier | `assessedSoftware.schema:identifier.@id` ?? `assessedSoftware.name` |
| name | `assessedSoftware.name` |
| software_name | same as `name`, aliased for native-filter binding |
| latest_version | MAX(`assessedSoftware.softwareVersion`) |
| url | MAX(`assessedSoftware.url`) |
| doi | `assessedSoftware.schema:identifier.@id` |
| first_seen / last_seen | MIN / MAX of `assessment_raw.created_at` |
| assessment_count | COUNT(DISTINCT assessment_raw.id) |
| project_id | `assessment_raw.project_id` |
| project_name | from `auth.projects` |

### dimensions

Quality dimensions from the EVERSE framework based on ISO/IEC 25010.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| identifier | VARCHAR | Unique identifier (e.g., "maintainability") |
| name | VARCHAR | Display name (e.g., "Maintainability") |
| description | TEXT | What this dimension measures |
| status | VARCHAR | Status (published, draft) |
| source | JSONB | Source metadata and references |
| created_at | TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | Last update time |

### indicators

Quality indicators that belong to dimensions, representing specific measurable criteria.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| identifier | VARCHAR | Unique identifier (e.g., "test_coverage") |
| name | VARCHAR | Display name |
| description | TEXT | What this indicator measures |
| status | VARCHAR | Status (published, draft) |
| quality_dimension | VARCHAR | Reference to parent dimension (JSON-encoded; one or many `{"@id": ".../slug"}`) |
| contact | JSONB | Contact information for the indicator |
| source | JSONB | Source metadata |
| created_at | TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | Last update time |

#### How dimensions and indicators are populated

Both tables are filled at runtime by the `sync_everse` ansible role
(`just sync-apply`) or the in-cluster `everse-sync` cronjob
(`just sync-trigger`). The role fetches the JSON-LD definitions from
<https://github.com/EVERSE-ResearchSoftware/indicators> and upserts them
via PostgREST. There is no SQL seed file -- the catalog stays in sync
with the upstream repo.

The view `api.indicators_flat` normalises `indicators.quality_dimension`
(stored as text-encoded JSON, sometimes a single object and sometimes an
array) into one row per (indicator, dimension) with a clean
`dimension_name` resolved from the dimensions table.

### assessment_raw

Raw assessment data stored as JSONB following the EVERSE JSON-LD format.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| payload | JSONB | Complete assessment in JSON-LD format |
| created_at | TIMESTAMP | Record creation time |

## Views

### Core Views

| View | Description |
|------|-------------|
| `assessment` | resqui-compatible view exposing JSON-LD fields |
| `assessments_detailed` | Full assessment info with check counts |
| `checks_detailed` | Unnested checks with indicator/dimension info |

### Dashboard Views

| View | Description |
|------|-------------|
| `assessment_summary` | Aggregated metrics per software |
| `dimension_coverage` | Pass/fail counts per dimension |
| `indicator_results` | Results grouped by indicator and status |
| `software_quality_scores` | Quality scores per software and dimension |
| `assessment_trends` | Monthly assessment statistics |
| `common_issues` | Frequently failing indicators |

## Derived Metric: Outcome

The only derived value the dashboards rely on is `outcome`, the
categorical bucket each check falls into. It is computed at view-time
from two raw payload fields, `checks[].output` and `checks[].status.@id`,
by the `check_outcome(check_item)` function in
`004_create_triggers.sql`:

- `Pass` <- `output` is `true`, `valid`, `pass`, `Pass`, `passed`, or
  `status.@id` contains `Pass`
- `Fail` <- `output` is `false`, `invalid`, `fail`, `Fail`, `failed`,
  or `status.@id` ends with `FailedActionStatus`
- `Not applicable` <- `output` is `n/a`, `na`, `not_applicable`,
  `NotApplicable`, `NA`, `error`, `Error`, `ERROR` (errored checks
  bucket here so a broken plugin isn't counted as a real failure)
- `Unknown` <- anything else (data-quality signal worth investigating)

Aggregations are done directly in Superset on top of
`api.assessment_checks`. Counts and distributions are computed per
chart via `COUNT(*)` and
`COUNT(*) FILTER (WHERE outcome = 'Fail')`-style metrics; there is no
rate, score, or threshold column anywhere in the data layer.

## Quality Dimensions and Indicators

Dimensions and indicators are not maintained in this document. They are synced
at deploy time from the EVERSE indicators repo
(`EVERSE-ResearchSoftware/indicators`) into the `dimensions` and `indicators`
tables by the `everse-sync` CronJob, so the live list always matches upstream.
Query them directly:

```sql
SELECT identifier, name FROM dimensions ORDER BY name;
SELECT identifier, name, quality_dimension FROM indicators ORDER BY name;
```

## Assessment Data Format

Assessments follow the EVERSE JSON-LD format (SoftwareQualityAssessment):

```json
{
  "@context": "https://w3id.org/everse/rsqa/0.0.1/",
  "@type": "SoftwareQualityAssessment",
  "name": "Assessment of NumPy",
  "dateCreated": "2025-01-15T10:30:00Z",
  "creator": {
    "@type": "schema:Person",
    "name": "Quality Assessor",
    "email": "assessor@example.com"
  },
  "assessedSoftware": {
    "@type": "schema:SoftwareApplication",
    "name": "NumPy",
    "softwareVersion": "1.26.0",
    "url": "https://github.com/numpy/numpy"
  },
  "checks": [
    {
      "@type": "CheckResult",
      "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/test_coverage" },
      "status": { "@id": "schema:CompletedActionStatus" },
      "output": "85.5",
      "evidence": "Coverage report from pytest-cov"
    }
  ]
}
```

### Check Result Values

Each check in an assessment can have different output types:

| Type | Example | Description |
|------|---------|-------------|
| Boolean | true/false | Pass/fail indicators (has_license, has_tests) |
| Numeric | 85.5 | Percentage or score (test_coverage, complexity) |
| String | "MIT" | Categorical values (license_type) |
| Status | Pass/Fail/NotApplicable | Check outcome |

## Assessment Storage

Assessments are stored as JSONB in `assessment_raw`. The `assessment` view provides a resqui-compatible interface:

```sql
-- Insert via view (triggers convert to JSONB)
INSERT INTO assessment ("@context", "@type", "dateCreated", ...)
VALUES ('https://w3id.org/everse/rsqa/0.0.1/', 'SoftwareQualityAssessment', ...);

-- Query via view
SELECT * FROM assessment;

-- Or query raw JSONB
SELECT payload->>'dateCreated', payload->'checks' FROM assessment_raw;
```

## Populating Test Data

Seed example assessments for development with the Ansible seed playbook:

```shell
just seed-data
```

## Schema Files

SQL schema definitions are in `deployment/database/sql/schema/`:

- `001_create_schema.sql` - Schema and roles
- `002_create_tables.sql` - Tables and base views
- `003_create_indexes.sql` - Indexes
- `004_create_triggers.sql` - Triggers for view inserts
- `005_setup_rls.sql` - Row-level security
- `006_create_views.sql` - Dashboard views
- `007_grant_permissions.sql` - Role permissions

These are loaded automatically during deployment via Terraform.

## Visibility Model

Two layers control who can see what, with the more specific layer
winning over the more general one:

1. **Project visibility** (`auth.projects.is_public`). Default: false
   (private). A public project's assessments are visible to anonymous
   visitors and any logged-in user. A private project's assessments are
   visible only to the project owner.
2. **Per-software override** (`auth.software_visibility`). Composite
   primary key `(software_name, owner_user_id)` with `is_public BOOLEAN`.
   When an override row exists for a given software_name and owner, it
   wins over the visibility of the project the owner's assessments for
   that software live in. The owner of the project always sees their own
   data regardless of the override -- the override controls what other
   viewers see, not the owner.

### Examples

| Project | Per-software override | Anonymous sees |
|---|---|---|
| public | none | yes |
| public | private | no |
| private | none | no |
| private | public | yes |

### Where this is enforced

- Anonymous + authenticated dashboard reads go through Superset, which
  receives a row-level-security (RLS) clause minted by
  `frontend/app/api/routes.py:_superset_guest_token_for`. The clause
  joins `auth.software_visibility` to `auth.projects` via
  `owner_user_id` and applies the rules above.
- Software-aware views (those that expose `software_name`) get the
  combined clause; pre-aggregated views without `software_name`
  (dimension_coverage, assessment_trends, ...) fall back to project-only
  visibility because the per-software override cannot be applied to
  pre-aggregated rows.

### Setting an override

`PUT /api/projects/me/software/visibility` (backend) with body
`{software_name, is_public}`:

- `is_public: true` -- anyone can see the assessments
- `is_public: false` -- only the owner can see them, even if the project
  is public
- `is_public: null` -- clear the override; visibility falls back to the
  project's setting

The same endpoint is exposed at `POST /account/software/visibility` on
the frontend portal so it can be driven by the account-page form.
