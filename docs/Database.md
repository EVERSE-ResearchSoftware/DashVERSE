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

### software

Stores metadata about registered research software projects.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| identifier | VARCHAR | Unique identifier (e.g., "numpy", "pandas") |
| name | VARCHAR | Display name |
| description | TEXT | Project description |
| version | VARCHAR | Current version |
| license | VARCHAR | License type (MIT, Apache-2.0, GPL-3.0, etc.) |
| repository_url | VARCHAR | Source code repository URL |
| homepage_url | VARCHAR | Project homepage URL |
| programming_language | VARCHAR[] | Array of programming languages used |
| created_at | TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | Last update time |

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
| quality_dimension | VARCHAR | Reference to parent dimension |
| contact | JSONB | Contact information for the indicator |
| source | JSONB | Source metadata |
| created_at | TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | Last update time |

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
| `software_languages` | Software grouped by programming language |

## Quality Dimensions

The EVERSE framework defines 11 quality dimensions based on ISO/IEC 25010:

| Dimension | Description |
|-----------|-------------|
| Maintainability | Ability to modify, update, and evolve software over time. Includes modularity, reusability, analyzability, and testability. |
| Usability | Ease of use and user experience. Includes learnability, operability, user error protection, and accessibility. |
| Reliability | Ability to perform required functions under stated conditions. Includes maturity, availability, fault tolerance, and recoverability. |
| Performance Efficiency | Performance relative to resource usage. Includes time behavior, resource utilization, and capacity. |
| Portability | Ease of transferring software between environments. Includes adaptability, installability, and replaceability. |
| Security | Information and data protection. Includes confidentiality, integrity, non-repudiation, and accountability. |
| Compatibility | Ability to exchange information with other products/systems. Includes co-existence and interoperability. |
| Functional Suitability | Degree software provides functions meeting stated/implied needs. Includes functional completeness, correctness, and appropriateness. |
| Reproducibility | Ability to reproduce computational results with same inputs/methods. Critical for research software. |
| FAIR Principles | Findability, Accessibility, Interoperability, Reusability of research software. |

Additional simplified dimensions include: Documentation, Testing, Licensing, Versioning, Community, Sustainability.

## Quality Indicators

Each dimension contains multiple indicators. Examples:

### Maintainability Indicators
- Documentation Coverage - Percentage of code with documentation
- Code Modularity - Use of independent, reusable modules
- Technical Debt Ratio - Estimated time to fix issues
- Code Complexity - Cyclomatic complexity metrics

### Usability Indicators
- User Documentation - Quality of README, tutorials, guides
- Installation Instructions - Clarity of setup documentation
- API Documentation - Quality of API reference
- Example Availability - Presence of usage examples

### Reliability Indicators
- Test Coverage - Percentage of code covered by tests
- Test Suite Quality - Presence of unit, integration, system tests
- Error Handling - Robustness of error handling
- Bug Fix Rate - Average time to resolve bugs

### Security Indicators
- Security Vulnerabilities - Known CVEs in dependencies
- No Leaked Credentials - No secrets in repository
- Static Analysis - Security scanning results

### FAIR Indicators
- Software Citation - CITATION.cff, codemeta.json
- License Clarity - Clear open-source license
- Persistent Identifier - DOI or persistent identifier
- Listed in Registry - Presence in software registries

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

The `database/populate_data.py` script generates fake data for development:

```shell
cd database
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=dashverse
export DB_USER=dashverse
export DB_PASSWORD=<password>
python populate_data.py --num_assessment 3
```

Use `--clear` to truncate tables before populating.

## Schema Files

SQL schema definitions are in `database/sql/schema/`:

- `001_create_schema.sql` - Schema and roles
- `002_create_tables.sql` - Tables and base views
- `003_create_indexes.sql` - Indexes
- `004_create_triggers.sql` - Triggers for view inserts
- `005_setup_rls.sql` - Row-level security
- `006_create_views.sql` - Dashboard views
- `007_grant_permissions.sql` - Role permissions

These are loaded automatically during deployment via Terraform.
