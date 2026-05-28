# Database

PostgreSQL schema, views, and seed data used by PostgREST and Superset.

## Structure

- `sql/schema/` -- DDL files (tables, indexes, triggers, RLS, views,
  grants). Applied on first PostgreSQL startup.
- `sql/data/` -- optional seed SQL applied on demand via `just seed-data`.
  Currently holds example assessments and a thin software-metadata table.

## Schema overview

Tables live in the `api` schema so PostgREST can expose them directly.
The `auth` schema is reserved for authentication tables.

## Deployment

The schema files in `sql/schema/` are loaded into Kubernetes as a
ConfigMap by the `db-init` Terraform module. PostgreSQL mounts the
ConfigMap at `/docker-entrypoint-initdb.d/` and runs the scripts in
alphabetical order on first startup.

To deploy:

```sh
just env=local deploy
```

## Where the data comes from

| Table / view | Source | How it is loaded |
|---|---|---|
| `dimensions` | EVERSE indicators repo on GitHub | Pulled at runtime by the `sync_everse` ansible role (`just sync-apply`) or the `everse-sync` cronjob in-cluster (`just sync-trigger`). No SQL seed file. |
| `indicators` | EVERSE indicators repo on GitHub | Same sync flow as `dimensions`. |
| `assessment_raw` | Per-deployment data | Example rows in `sql/data/004_assessment_examples.sql`, applied by `just seed-data`. In production, populated by the EVERSE Quality Pipeline submitting via PostgREST. |
| `software_metadata` | Per-deployment data | Example rows in `sql/data/005_software_metadata.sql`, applied by `just seed-data`. |
| Everything else (views) | Computed from the tables above | Defined in `sql/schema/006_create_views.sql`. |

The EVERSE catalog lives at
<https://github.com/EVERSE-ResearchSoftware/indicators>; the sync role
reads `dimensions/` and `indicators/` from there.
