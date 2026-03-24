# Apache Superset Datasets and Views

This document describes the available datasets, views, metrics, and visualization capabilities in DashVERSE Superset.

## Overview

DashVERSE uses Apache Superset to visualize research software quality assessment data. Superset connects to the PostgreSQL database and provides interactive dashboards for exploring quality metrics across software projects, dimensions, and indicators.

### What You Can Analyze

- **Software Quality Scores**: Overall and per-dimension quality scores for each software project
- **Dimension Coverage**: How well software performs across quality dimensions (Testing, Documentation, Security, etc.)
- **Indicator Results**: Pass/fail rates for specific quality indicators
- **Assessment Trends**: How quality metrics change over time
- **Common Issues**: Most frequently failing quality checks across all software
- **Language Distribution**: Quality metrics grouped by programming language

## Datasets Overview

Superset datasets are connected to PostgreSQL tables and views in the `api` schema.

| Dataset                 | Source Type | Description                                     |
| ----------------------- | ----------- | ----------------------------------------------- |
| dimensions              | Table       | EVERSE quality dimensions                       |
| indicators              | Table       | Quality indicators linked to dimensions         |
| software                | Table       | Registered research software projects           |
| assessments             | Table       | Raw assessment data in JSONB format             |
| assessments_detailed    | View        | Full assessment info with computed fields       |
| checks_detailed         | View        | Individual checks with indicator/dimension info |
| assessment_summary      | View        | Aggregated metrics per software                 |
| dimension_coverage      | View        | Pass/fail statistics per dimension              |
| indicator_results       | View        | Results grouped by indicator and status         |
| software_quality_scores | View        | Quality scores per software and dimension       |
| assessment_trends       | View        | Monthly assessment statistics                   |
| common_issues           | View        | Frequently failing indicators                   |
| software_languages      | View        | Software by programming language                |

## Available Metrics

### Per-Software Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| Assessment Count | assessment_summary | Total number of assessments performed |
| Latest Assessment Date | assessment_summary | Date of most recent assessment |
| Average Checks | assessment_summary | Average number of checks per assessment |
| Unique Indicators | assessment_summary | Number of distinct indicators assessed |
| Overall Quality Score | software_quality_scores | Aggregate pass rate across all dimensions |

### Per-Dimension Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| Total Checks | dimension_coverage | Number of checks in this dimension |
| Passed Checks | dimension_coverage | Checks with Pass status |
| Failed Checks | dimension_coverage | Checks with Fail status |
| Pass Rate | dimension_coverage | Percentage of passed checks (0-100) |

### Per-Indicator Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| Occurrences | indicator_results | Count of checks for this indicator |
| Status Distribution | indicator_results | Breakdown by Pass/Fail/NotApplicable |
| Failure Count | common_issues | Number of failures across all software |
| Affected Software | common_issues | List of software failing this indicator |

### Trend Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| Monthly Assessments | assessment_trends | Number of assessments per month |
| Monthly Software Count | assessment_trends | Unique software assessed per month |
| Monthly Average Checks | assessment_trends | Average checks per assessment per month |

## Dataset Columns

### dimensions

Quality dimensions from the EVERSE framework.

| Column      | Type      | Description                         |
| ----------- | --------- | ----------------------------------- |
| id          | INTEGER   | Primary key                         |
| identifier  | VARCHAR   | Unique identifier (e.g., "testing") |
| name        | VARCHAR   | Display name (e.g., "Testing")      |
| description | TEXT      | Detailed description                |
| status      | VARCHAR   | Status (published, draft)           |
| source      | JSONB     | Source metadata                     |
| created_at  | TIMESTAMP | Record creation time                |
| updated_at  | TIMESTAMP | Last update time                    |

### indicators

Quality indicators linked to dimensions.

| Column            | Type      | Description                                 |
| ----------------- | --------- | ------------------------------------------- |
| id                | INTEGER   | Primary key                                 |
| identifier        | VARCHAR   | Unique identifier (e.g., "IND-testing-001") |
| name              | VARCHAR   | Display name                                |
| description       | TEXT      | What this indicator measures                |
| status            | VARCHAR   | Status (published, draft)                   |
| quality_dimension | VARCHAR   | Reference to parent dimension               |
| contact           | JSONB     | Contact information                         |
| source            | JSONB     | Source metadata                             |
| created_at        | TIMESTAMP | Record creation time                        |
| updated_at        | TIMESTAMP | Last update time                            |

### software

Registered research software projects.

| Column               | Type      | Description                          |
| -------------------- | --------- | ------------------------------------ |
| id                   | INTEGER   | Primary key                          |
| identifier           | VARCHAR   | Unique identifier                    |
| name                 | VARCHAR   | Display name                         |
| description          | TEXT      | Project description                  |
| version              | VARCHAR   | Current version                      |
| license              | VARCHAR   | License type (MIT, Apache-2.0, etc.) |
| repository_url       | VARCHAR   | Source code repository URL           |
| homepage_url         | VARCHAR   | Project homepage URL                 |
| programming_language | VARCHAR[] | Array of programming languages       |
| created_at           | TIMESTAMP | Record creation time                 |
| updated_at           | TIMESTAMP | Last update time                     |

### assessments (assessment_raw)

Raw assessment data stored as JSONB.

| Column     | Type      | Description                           |
| ---------- | --------- | ------------------------------------- |
| id         | INTEGER   | Primary key                           |
| payload    | JSONB     | Complete assessment in JSON-LD format |
| created_at | TIMESTAMP | Record creation time                  |

### assessments_detailed

Full assessment information with computed fields.

| Column           | Type      | Description                |
| ---------------- | --------- | -------------------------- |
| id               | INTEGER   | Assessment ID              |
| context          | TEXT      | JSON-LD context URL        |
| type             | TEXT      | Assessment type            |
| date_created     | TEXT      | Assessment date            |
| software_name    | TEXT      | Name of assessed software  |
| software_version | TEXT      | Version assessed           |
| software_url     | TEXT      | Repository URL             |
| total_checks     | INTEGER   | Number of checks performed |
| checks           | JSONB     | Full check results array   |
| created_at       | TIMESTAMP | Record creation time       |

### checks_detailed

Individual checks unnested from assessments with indicator and dimension information.

| Column            | Type    | Description                        |
| ----------------- | ------- | ---------------------------------- |
| assessment_id     | INTEGER | Parent assessment ID               |
| software_name     | TEXT    | Software being assessed            |
| assessment_date   | TEXT    | Date of assessment                 |
| check_type        | TEXT    | Type of check                      |
| indicator_id      | TEXT    | Indicator being assessed           |
| checking_software | TEXT    | Tool that performed the check      |
| process           | TEXT    | Check process description          |
| status            | TEXT    | Result (Pass, Fail, NotApplicable) |
| output            | TEXT    | Check output or message            |
| evidence          | TEXT    | Supporting evidence                |
| indicator_name    | TEXT    | Human-readable indicator name      |
| quality_dimension | TEXT    | Parent dimension reference         |
| dimension_name    | TEXT    | Human-readable dimension name      |

### assessment_summary

Aggregated metrics per software project.

| Column            | Type    | Description                   |
| ----------------- | ------- | ----------------------------- |
| software_name     | TEXT    | Software name                 |
| software_url      | TEXT    | Repository URL                |
| assessment_count  | BIGINT  | Total assessments             |
| latest_assessment | TEXT    | Most recent assessment date   |
| avg_checks        | NUMERIC | Average checks per assessment |
| unique_indicators | BIGINT  | Unique indicators assessed    |

### dimension_coverage

Pass/fail statistics per quality dimension.

| Column         | Type    | Description                    |
| -------------- | ------- | ------------------------------ |
| dimension_name | TEXT    | Dimension name                 |
| dimension_id   | TEXT    | Dimension identifier           |
| total_checks   | BIGINT  | Total checks in this dimension |
| passed         | BIGINT  | Checks with Pass status        |
| failed         | BIGINT  | Checks with Fail status        |
| other          | BIGINT  | Checks with other status       |
| pass_rate      | NUMERIC | Percentage of passed checks    |

### indicator_results

Results grouped by indicator and status.

| Column            | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| indicator_id      | TEXT    | Indicator identifier              |
| indicator_name    | TEXT    | Indicator name                    |
| quality_dimension | TEXT    | Parent dimension reference        |
| dimension_name    | TEXT    | Dimension name                    |
| status            | TEXT    | Check status                      |
| occurrences       | BIGINT  | Count of this status              |
| percentage        | NUMERIC | Percentage of total for indicator |

### software_quality_scores

Quality scores per software and dimension.

| Column         | Type    | Description              |
| -------------- | ------- | ------------------------ |
| software_name  | TEXT    | Software name            |
| dimension_name | TEXT    | Dimension name           |
| total_checks   | BIGINT  | Checks in this dimension |
| passed         | BIGINT  | Passed checks            |
| score          | NUMERIC | Pass rate as percentage  |

### assessment_trends

Monthly assessment statistics.

| Column         | Type      | Description                   |
| -------------- | --------- | ----------------------------- |
| month          | TIMESTAMP | Month (truncated date)        |
| assessments    | BIGINT    | Assessments in this month     |
| software_count | BIGINT    | Unique software assessed      |
| avg_checks     | NUMERIC   | Average checks per assessment |

### common_issues

Frequently failing indicators across all assessments.

| Column            | Type   | Description                     |
| ----------------- | ------ | ------------------------------- |
| indicator_id      | TEXT   | Indicator identifier            |
| indicator_name    | TEXT   | Indicator name                  |
| dimension_name    | TEXT   | Parent dimension                |
| failure_count     | BIGINT | Number of failures              |
| affected_software | TEXT[] | Software affected by this issue |

### software_languages

Software projects with programming languages.

| Column        | Type      | Description                 |
| ------------- | --------- | --------------------------- |
| id            | INTEGER   | Software ID                 |
| software_name | TEXT      | Software name               |
| language      | VARCHAR[] | Programming languages array |

## Dashboard Use Cases

### Software Quality Overview

Use `software_quality_scores` to create:
- Heatmap of software vs. dimensions with quality scores
- Bar charts comparing software projects
- Ranking tables of best/worst performing software

### Dimension Analysis

Use `dimension_coverage` to create:
- Pie charts showing pass/fail distribution per dimension
- Bar charts comparing dimensions by pass rate
- Identify which dimensions need improvement

### Indicator Deep Dive

Use `indicator_results` and `common_issues` to create:
- Tables of frequently failing indicators
- Bar charts showing indicator pass rates
- Lists of software affected by specific issues

### Trend Analysis

Use `assessment_trends` to create:
- Line charts showing assessment volume over time
- Track quality improvements month over month
- Monitor assessment coverage

### Drill-Down Analysis

Use `checks_detailed` to create:
- Detailed tables of individual check results
- Filter by software, dimension, or indicator
- View evidence and process descriptions

## Filters and Drill-Downs

Common filter dimensions available:

| Filter | Description | Applicable Datasets |
|--------|-------------|---------------------|
| software_name | Filter by specific software | All views |
| dimension_name | Filter by quality dimension | dimension_coverage, indicator_results, software_quality_scores |
| indicator_name | Filter by quality indicator | indicator_results, checks_detailed, common_issues |
| status | Filter by check outcome | checks_detailed, indicator_results |
| assessment_date | Filter by date range | checks_detailed, assessment_trends |
| programming_language | Filter by language | software_languages, software |

## Example Queries

### Top 10 Software by Quality Score

```sql
SELECT software_name, AVG(score) as avg_score
FROM software_quality_scores
GROUP BY software_name
ORDER BY avg_score DESC
LIMIT 10;
```

### Dimensions with Lowest Pass Rates

```sql
SELECT dimension_name, pass_rate
FROM dimension_coverage
ORDER BY pass_rate ASC;
```

### Most Common Quality Issues

```sql
SELECT indicator_name, dimension_name, failure_count
FROM common_issues
ORDER BY failure_count DESC
LIMIT 10;
```

### Assessment Activity by Month

```sql
SELECT month, assessments, software_count
FROM assessment_trends
ORDER BY month DESC;
```
