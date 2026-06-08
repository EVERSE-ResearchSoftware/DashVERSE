# DashVERSE codebase guide

A short tour for new contributors and returning maintainers.

## What it is

DashVERSE stores JSON-LD software-quality assessments (the kind generated
by [QualityPipelines](https://github.com/EVERSE-ResearchSoftware/QualityPipelines))
in a PostgreSQL database and surfaces them through five Apache Superset
dashboards embedded in a small frontend site.

## How the pieces fit

PostgreSQL is the source of truth. JSONB columns hold the rsqa payloads
as-is; views in `deployment/database/sql/schema/006_create_views.sql` flatten them
for the dashboards. PL/pgSQL triggers in `004_create_triggers.sql`
validate incoming payloads and normalise derived values (pass/fail
outcome, dimension lookup).

PostgREST auto-generates a REST API from the `api` schema with no
application code in between -- a new column on a view becomes a
queryable field. Anonymous users can read; writes require a JWT issued
by `backend` (a small FastAPI app handling registration, login,
and Argon2id-hashed passwords).

Apache Superset reads the views directly and renders the role
dashboards (Policy Maker, Principal Investigator, Research Software
Engineer, Researcher Who Codes, Trainer). The `frontend/` site is a
FastAPI service that embeds those dashboards in iframes for a public
homepage.

OpenTofu (`deployment/terraform/`) deploys the whole stack via the Kubernetes and
Helm providers; post-install steps that have to call Superset's REST
API live in Ansible (`deployment/ansible/roles/superset_config/`). `just` is the
front door for day-to-day commands; `nix develop` provides every CLI
dependency.

## Where to look for X

| If you want to... | Look at |
|---|---|
| Change the database schema | `deployment/database/sql/schema/00*.sql` |
| Surface a new JSONB field as a column | `deployment/database/sql/schema/006_create_views.sql` |
| Validate an assessment field on insert | `validate_assessment_payload()` in `deployment/database/sql/schema/004_create_triggers.sql` |
| Add an auth endpoint | `backend/app/api/` |
| Add a route to the frontend site | `frontend/app/api/routes.py` |
| Edit a dashboard or chart | The Superset UI, then `just export-superset-assets`. See [`dashboards.md`](dashboards.md). |
| Add a K8s deployment | New module under `deployment/terraform/modules/`, wired in `deployment/terraform/main.tf` |
| Add a CLI shortcut | New recipe in `justfile` |

## Local development

See [`../README.dev.md`](../README.dev.md) for the deploy walk-through
and the list of `just` recipes.

## Known constraints

- `deployment/database/sql/data/004_assessment_examples.sql` is hand-written SQL,
  not a templated loader. To add a seed assessment, copy an existing
  `INSERT INTO assessment_raw` block and edit. Idempotent via the
  `urn:dashverse:seed:%` `@id` prefix.
- The `indicators.quality_dimension` column is `VARCHAR` but stored as
  JSON-encoded text (string, object, or array depending on the upstream
  shape). The dashboard views unwrap all three forms with a
  `CASE WHEN jsonb_typeof(...)` block.
- The sync CronJob in `deployment/terraform/modules/sync/main.tf` and the Ansible
  `sync_everse` role build SQL by string substitution with
  single-quote-only escaping. Fragile under unusual upstream content.

## See also

- [`../README.dev.md`](../README.dev.md) -- deploy + recipe reference
- [`../Database.md`](../Database.md) -- schema reference
- [`../Superset.md`](../Superset.md) -- list of datasets and views
- [`../API_examples.md`](../API_examples.md) -- PostgREST and backend curl examples
- [`dashboards.md`](dashboards.md) -- adding or editing charts and dashboards
- [`../user/editing-dashboards.md`](../user/editing-dashboards.md) -- end-user UI walkthrough
