# Apache Superset Datasets and Dashboards

DashVERSE renders its dashboards inside an embedded Apache Superset.
This page lists the actual datasets, dashboards, and key filtering
behaviour as they exist on the current pinned schema.

For the editing workflow see `docs/developer/dashboards.md` (for
maintainers) and `docs/user/editing-dashboards.md` (for users).

## Architecture at a glance

```
PostgREST                      Superset                       Frontend
  |                              |                              |
  +-- api.assessment_checks   <--+  (8 datasets, 30+ charts)    |
  +-- api.catalog_coverage    <--+  (3 dashboards)              |
  +-- api.dimensions          <--+   |                          |
  +-- api.indicators          <--+   +-- iframe embed  -------> /dashboard/<slug>
  +-- api.projects            <--+
  +-- api.*_flat / *_with_links--+
```

Superset reads directly from PostgreSQL via its dbapi connection (not
PostgREST). RLS still applies because the `assessment_checks` and
`projects` views use `security_invoker = true`, so the calling role's
privileges determine row visibility. The embedded SDK then mints a
guest token per page load that injects two RLS clauses keyed off
`effective_visibility` and `visibility` columns.

## Datasets

All datasets live in the `api` schema. Eight are imported into Superset
via the Ansible role `superset_config`.

| Dataset | Backing object | Used by | Notes |
|---|---|---|---|
| `assessment_checks` | view | every Overview + Assessments chart | one row per (assessment x check); the dashboard's fact table |
| `projects` | view | Project native filter | thin wrapper over `auth.projects` |
| `dimensions` | table | Catalog dashboard | reference data; populated by the `everse-sync` CronJob |
| `indicators` | table | Catalog dashboard | reference data; populated by the same job |
| `dimensions_with_links` | view | RSQKit drill-down columns | enriches `dimensions` with URL columns |
| `indicators_flat` | view | RSQKit drill-down columns | enriches `indicators` with parent dimension and URLs |
| `catalog_coverage` | view | Catalog dashboard KPI / Catalog Coverage chart | overall Tested / Untested split |
| `catalog_coverage_breakdown` | view | Catalog dashboard table | per-dimension Tested / Untested counts |

The Superset YAML files live under
`deployment/ansible/files/superset_assets/datasets/DashVERSE/` and are
re-imported on every `just env=<env> setup-dashboards` run.

## Key columns on `assessment_checks`

This is the most-used dataset; its columns drive almost every chart and
filter on the Overview and Assessments dashboards.

| Column | Type | Source |
|---|---|---|
| `assessment_id` | bigint | `assessment_raw.id` |
| `assessed_at` | timestamp | parsed from `payload->>'dateCreated'` |
| `ingested_at` | timestamp | `assessment_raw.created_at` |
| `software_name` | text | `payload->'assessedSoftware'->>'name'` (COALESCE'd to `(unknown software)`) |
| `software_version` | text | `payload->'assessedSoftware'->>'softwareVersion'` |
| `software_url` | text | `payload->'assessedSoftware'->>'url'` |
| `software_doi` | text | from `assessedSoftware.schema:identifier` when present |
| `author_user_id` | int | from `assessment_raw.created_by`, set by the JWT capture trigger |
| `author_username` | text | joined from `auth.users` |
| `author_full_name` | text | `COALESCE(creator.name, username)` |
| `project_id` | bigint | `assessment_raw.project_id` |
| `project_name` | text | joined from `auth.projects` |
| `project_visibility` | text | private \| authenticated \| public |
| `effective_visibility` | text | `COALESCE(software_visibility.visibility, project.visibility, 'public')` |
| `tool_name` | text | from `checks[i].checkingSoftware.name` |
| `indicator_name` | text | joined from `indicators` (COALESCE to `(unmapped indicator)`) |
| `indicator_url` | text | `payload->...->>'assessesIndicator.@id'` |
| `dimension_name` | text | joined from `dimensions` (COALESCE to `(unmapped dimension)`) |
| `output` (raw) | text | `checks[i].output` |
| `outcome` | text | normalised: `Pass` \| `Fail` \| `Not applicable` \| `Unknown` |
| `evidence` | text | `checks[i].evidence` |

The `outcome` column is computed by the `check_outcome()` PL/pgSQL
function in `004_create_triggers.sql`. Outputs the function does not
recognise land in `Unknown`. Plugin runtime errors (`output: "error"`)
are deliberately classified as `Not applicable` so a broken tool does
not drag the pass rate down.

## Visibility and RLS

The `assessment_checks` and `projects` datasets are
`security_invoker = true` views. Per-page guest tokens minted in
`frontend/app/api/routes.py` add two RLS clauses to the dataset query:

- **Anonymous viewer**: `effective_visibility = 'public'` on
  assessment_checks; `visibility = 'public'` on projects.
- **Authenticated viewer**: `effective_visibility IN ('public', 'authenticated') OR author_user_id = <uid>`,
  similarly for projects (`visibility IN (...) OR owner_user_id = <uid>`).

So an embedded dashboard transparently scopes its rows to whatever the
viewer is allowed to see. The same RLS clauses also scope the
Author / Project / Software filter dropdowns -- a private project's
author does not surface as a filter option for someone who can't read
that project's rows.

## Dashboards

Three dashboards ship with DashVERSE. Each is defined in a YAML file
under `deployment/ansible/files/superset_assets/dashboards/`.

### Overview

Slug: `global`. Anchor for first-time visitors. Three KPI cards above
a Catalog Coverage donut.

| Row | Content |
|---|---|
| 1 (KPIs, width 4 each) | Total Assessments, Total Projects, Total Software |
| 2 | Catalog Coverage donut (full width) |
| 3 | Dimension Profile (stacked horizontal bars) |

The Total Checks, Passed, Failed, and Pass Rate KPI cards live on the
account page (`/account`) instead of here, rendered server-side from
`/api/stats/home`.

### Assessments

Slug: `assessments`. The exploration dashboard. Filter chips on top:
Author, Project, Software, Dimension, Assessment date.

| Row | Content |
|---|---|
| intro | Markdown introduction |
| 1 | Quality Across Projects (wide) |
| 2 | Assessment Activity Over Time + Outcome Trend stacked area |
| 3 | Outcomes Heatmap (wide) |
| 4 | Dimension Profile + Outcome Mix donut |
| 5 | Top Performing Software (wide) |
| improve | Improvement Targets Profile chart |
| | Improvement Targets table (wide) |
| failed | Failed Checks Profile chart |
| detail | Failed Checks Detail table (wide) |
| | Recent Assessments table (wide) |
| sw improve | Software Improvement Visual + Software Improvement Targets |
| | Outcomes Heatmap (wide) |

There is intentionally no Outcome filter chip; Outcome Mix and Outcome
Trend are themselves the breakdown by outcome and cross-filter clicks
already narrow other charts.

### Catalog

Slug: `catalog`. Reference data only; what is in the EVERSE
indicators/dimensions catalog and which of those have been tested by
at least one assessment in scope.

Charts: Catalog Coverage donut, Dimensions Coverage, Indicators
Coverage, Dimensions Tested, Indicators Tested, Indicators per
Dimension, Coverage per Tool, plus a Dimensions Detail and Indicators
Detail table.

## Colour palette

The Pass / Fail / Not applicable categorical palette uses the Paul
Tol bright colour set, picked for deuteranopia / protanopia / tritanopia
safety:

| Label | Hex | Used for |
|---|---|---|
| Pass | `#117733` | green, also "Tested" on catalog charts |
| Fail | `#CC3311` | red |
| Not applicable | `#666666` | neutral gray, also "Untested" |

All chart YAMLs share the same `label_colors` map for these three
labels.

## Filters and cross-filtering

Native filter bar (Assessments dashboard):

- Author (uses `author_username`, scoped by RLS)
- Project (`project_name`)
- Software (`software_name`)
- Dimension (`dimension_name`)
- Assessment date (`assessed_at`)

Every native filter sets `chartsInScope` to every chart on the
dashboard, so clicks anywhere narrow the whole page.

Cross-filters: clicking a slice or row in one chart filters every
other chart on the same dashboard. Configured per chart in
`chart_configuration` inside the dashboard YAML.

Both filter dropdowns and cross-filter results are scoped by the same
RLS clauses applied to the underlying dataset query.

## Example PostgREST queries

The same views are also exposed via PostgREST as REST endpoints. These
are useful for verifying what the dashboard "should" be showing.

```bash
# distinct authors I can see
. ./scripts/.env && curl -sS -H "Authorization: Bearer $DASHVERSE_TOKEN" \
  "https://api.dashverse.cloud/assessment_checks?select=author_username" \
  | jq -r '.[].author_username' | sort -u

# my pass rate per dimension
curl -sS -H "Authorization: Bearer $DASHVERSE_TOKEN" \
  "https://api.dashverse.cloud/assessment_checks?author_user_id=eq.<my_uid>&select=dimension_name,outcome" \
  | jq 'group_by(.dimension_name) | map({dim:.[0].dimension_name, total:length, passed:[.[] | select(.outcome=="Pass")] | length}) | map(. + {rate: (100*.passed/.total | floor)})'

# what is in the (unmapped indicator) bucket
curl -sS -H "Authorization: Bearer $DASHVERSE_TOKEN" \
  "https://api.dashverse.cloud/assessment_checks?indicator_name=eq.(unmapped%20indicator)&select=indicator_url&limit=20" \
  | jq -r '.[].indicator_url' | sort -u
```

## Caching

Superset's chart data cache uses Redis with a 60-second TTL (configured
in `deployment/terraform/modules/superset/values.yaml.tpl`). The Ansible
role busts the cache for every DashVERSE dataset at the end of every
`setup-dashboards` run, so a column rename or chart edit shows up
immediately. Manual bust: `POST /superset/refresh` on the frontend.
