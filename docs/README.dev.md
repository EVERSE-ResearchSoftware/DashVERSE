# DashVERSE Developer Notes

## Requirements

- [just](https://github.com/casey/just)
- [OpenTofu (1.6+) or Terraform (1.6+)]()
- [kubectl (1.28+)]()
- [helm (3.0+)](https://helm.sh/docs/intro/install)
- [minikube (1.30+)](https://minikube.sigs.k8s.io/docs/start)
- [Docker](https://docs.docker.com/engine/install) or [Podman](https://podman.io/docs/installation)
- [Ansible (2.9+)]()
- [Python](https://www.python.org/downloads)

If you have Nix installed, all dependencies are provided via `nix develop`.

## Deployment configurations

The deployment settings for both local (testing) and production environments can be found in `deployment/terraform/environments` folder.

## Deployment

TLDR:
  just destroy-all          # tear down everything including minikube
  minikube start            # if needed
  just deploy               # build images + tofu apply
  just sync-apply           # download EVERSE indicators/dimensions + import
  just seed-data            # import sample assessment data
  just port-forward         # in another terminal -- keep it running
  just setup-dashboards     # configure Superset (dataset -> chart ->
  dashboard imports + normalize)

### Quick Start

1. Start minikube

   **Note:** If you already have a kubernetes cluster, you can skip this step.

   ```shell
   minikube start --cpus='4' --memory='4g'
   ```

1. Deploy the services locally

   ```shell
   just deploy
   ```

   `env` defaults to `local`; nothing to pass for a local minikube
   deploy. For a real production target set it explicitly:
   `just env=production deploy`.

1. Verify pods are running

   ```shell
   just status
   ```

1. Do port forwarding for the services to be able to access
   On a `separate terminal` do port forwarding to be able to access the service. Make sure to keep this terminal for the next steps.

   ```shell
   just port-forward
   ```

1. Deploy preconfigured dashboards

   ```shell
   just setup-dashboards
   ```

1. Access services

   Then open:

   - Superset: http://localhost:8088
   - PostgREST API: http://localhost:3000
   - PostgREST API Docs: http://localhost:3001
   - Backend: http://localhost:8000
   - Backend API Docs: http://localhost:8001
   - Frontend site: http://localhost:8080

At this point should have all the configured services and preconfigured dashboards available. You can start adding assessment data to the dashboard.

### Sample Data

To populate the system with sample software and assessments for testing:

```shell
just seed-data
```

The data will appear in the Superset dashboards.

### Credentials

Service credentials are auto-generated during deployment and stored securely in Kubernetes secrets. To retrieve them:

```shell
just show-access
```

This displays:

- PostgreSQL connection details
- Superset admin login

You can also retrieve individual credentials with kubectl:

```shell
# PostgreSQL password
kubectl get secret dashverse-secrets -n dashverse -o jsonpath='{.data.postgres-password}' | base64 -d

# Superset admin password
kubectl get secret dashverse-secrets -n dashverse -o jsonpath='{.data.superset-admin-password}' | base64 -d
```

### Manual Deployment

```shell
cd deployment/terraform
tofu init
tofu apply -var-file="environments/local.tfvars"
```

### Production Deployment

```shell
# Deploy all services (builds images and applies Terraform)
just env=production deploy

# Populate data
just sync-apply
just seed-data

# Configure Superset dashboards
just env=production setup-dashboards
```

The production configuration (`deployment/terraform/environments/production.tfvars`) includes settings for external URLs used in iframe embedding.

### Sync EVERSE Data

Indicators and dimensions are synced from the EVERSE repository:
https://github.com/EVERSE-ResearchSoftware/indicators

The sync runs automatically daily at 2am via a CronJob. To trigger manually:

```shell
just sync-trigger
```

Or to sync outside the cluster:

```shell
just sync-apply
```

### Authentication

The Backend provides a web interface for user registration and JWT token generation.

1. Open http://localhost:8000 (after port-forward)
2. Register a new account
3. Login and generate an API token
4. Use the token for PostgREST write access

Alternatively, generate a token via CLI (register a user first):

```shell
just jwt <username> <password>
```

### API Documentation

Interactive API documentation is provided using [Scalar](https://scalar.com/):

- **PostgREST API Docs**: http://localhost:3001 - Database REST interface with all available endpoints
- **Backend API Docs**: http://localhost:8001 - Authentication endpoints for user management and JWT tokens

The documentation is automatically generated from OpenAPI specifications and includes an interactive request builder.

### Dashboard Configuration

After deployment, configure Superset with pre-built dashboards using Ansible:

```shell
just setup-dashboards
```

This creates five role-based dashboards based on [RSQKit roles](https://everse.software/RSQKit/your_role):

- **[Policy Maker](https://everse.software/RSQKit/policy_maker)** - High-level adoption and compliance overview
- **[Principal Investigator](https://everse.software/RSQKit/principal_investigator)** - Project-level metrics and action items
- **[Research Software Engineer](https://everse.software/RSQKit/research_software_engineer)** - Technical metrics and detailed check results
- **[Researcher Who Codes](https://everse.software/RSQKit/researcher_who_codes)** - Practical guidance and quick improvements
- **[Trainer](https://everse.software/RSQKit/trainer)** - Training insights and best practices

Prerequisites:

- Ansible (2.9+)
- Port forwarding running (`just port-forward`)
- Superset accessible at localhost:8088

The Superset admin password is automatically retrieved from Kubernetes secrets during setup.

### Chart-Data Cache

The Superset chart-data cache is **disabled by default in local deployments**
via `DATA_CACHE_CONFIG = {"CACHE_TYPE": "NullCache"}` in
`deployment/terraform/modules/superset/values.yaml.tpl` (under `configOverrides.no_data_cache`).
Every chart query hits Postgres directly, so any change you make -- editing a
chart YAML, re-importing dashboards, pushing fresh assessments -- appears on the
next page reload without needing to bust anything manually.

To re-enable caching (closer to production behaviour), remove or comment out
the `no_data_cache` block in the values template and apply just the Superset
module:

```shell
tofu apply -target=module.superset -var-file=environments/local.tfvars
```

Then restart the Superset pod so the new config is loaded:

```shell
kubectl rollout restart deployment/superset -n dashverse
```

With caching back on, chart responses are served from Redis until the dataset's
`cache_timeout` expires (or the global default takes over). To bust the cache
on demand:

- `POST http://localhost:8080/superset/refresh` -- invalidates every
  project-aware dataset in one call (this is what
  `frontend/app/api/routes.py:_superset_invalidate_datasets` calls after a
  project rename, visibility flip, or bulk data load).
- Superset's own `POST /api/v1/cachekey/invalidate` endpoint for a custom
  dataset UID list.

Why disable it during development: edits to chart YAMLs propagate immediately,
and freshly pushed assessments are visible without waiting for the dataset
cache to expire. Why not in production: every chart load hits Postgres, which
is fine for one developer but multiplies database load under concurrent users.

Filter-state and explore-form caches stay enabled either way -- the
`?native_filters_key=...` permalink workflow used by `?software=<id>` and
`/me/assessments` depends on those.

## Documentation

- `docs/developer/codebase.md` - the entry point for new contributors: how the pieces fit, where things live, and the per-component rationale.
- `docs/developer/dashboards.md` - how to add or edit charts and dashboards in code (export from the Superset UI, commit the YAML).
- `docs/user/editing-dashboards.md` - end-user UI walkthrough for editing charts and dashboards in the Superset interface.
- `docs/Database.md` - PostgreSQL schema, view definitions, and assessment payload mapping.
- `docs/Superset.md` - list of registered datasets and views.
- `docs/Kubernetes.md` - operational commands for the Minikube deployment.
- `docs/API_examples.md` - practical PostgREST calls, including the multi-step workflow for creating assessments.

## Clean up

Remove all deployed resources:

```shell
just destroy
```

Delete the resources and the minikube cluster:

```shell
just destroy-all
```
