# DashVERSE Developer Notes

## Requirements

Tools:

- [just](https://github.com/casey/just)
- [OpenTofu (1.6+) or Terraform (1.6+)](https://opentofu.org/docs/intro/install/)
- [kubectl (1.28+)](https://kubernetes.io/docs/tasks/tools/)
- [helm (3.0+)](https://helm.sh/docs/intro/install)
- [minikube (1.30+)](https://minikube.sigs.k8s.io/docs/start) -- both `env=local` and `env=production` run on minikube
- [Docker](https://docs.docker.com/engine/install) or [Podman](https://podman.io/docs/installation)
- [Ansible (2.9+)](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
- [Python](https://www.python.org/downloads)
- standard shell utils: `curl`, `jq`, `nc`/`netcat`, `base64` (preflight check verifies these are on PATH)

System:

- **Linux with systemd** is required on the host running `just deploy`. The
  deploy installs a **systemd-user unit** (`dashverse-port-forward.service`)
  that keeps `kubectl port-forward` alive across pod rollouts. macOS and WSL1
  hosts skip the unit install with a warning -- you'll need to keep
  `just port-forward` running in a terminal yourself.
- On Linux, run `loginctl enable-linger $USER` once so the unit keeps
  running when you're logged out (the deploy does this automatically if
  `loginctl` is on PATH).
- For production, a Cloudflare Tunnel (`cloudflared`) typically routes
  public hostnames to `localhost` ports -- managed outside this repo.

If you have Nix installed, all the tool dependencies are provided via `nix develop`.

## Deployment configurations

The deployment settings for both local (testing) and production environments can be found in `deployment/terraform/environments` folder.

## Deployment

TLDR -- single command from a fresh host:

```
just deploy                  # local minikube
just env=production deploy   # production VM

# add VERBOSE=1 to see the full output of every sub-step (tofu plan,
# ansible recap, kubectl rollouts) instead of just the step headers:
VERBOSE=1 just deploy
```

The recipe runs 10 numbered steps. By default only the step headers print
(`==> [N/10] description`); the rest is captured to per-step log files
under `/tmp/dashverse-deploy-*` and only surfaced on failure (last 60
lines). The steps cover: preflight checks, image builds, Terraform apply
(including the schema-apply Job that reconciles all SQL files), the
port-forward systemd unit, two waits for Superset readiness, a one-shot
sync of the EVERSE indicators/dimensions catalog, and finally the Ansible
import of dashboards + chart-cache flush.

Standalone helpers if you need to run individual phases:

```
just port-forward-install    # (re)install the systemd-user port-forward unit
just port-forward-status     # one-line state of the unit
just trigger-sync            # one-shot dimensions/indicators sync
just setup-dashboards        # Ansible: dataset + chart + dashboard imports + cache flush
```

### Pinning upstream dependencies

DashVERSE depends on two external repositories whose contents flow into
the running stack:

| Upstream | Used by | Default | How to pin |
|---|---|---|---|
| [EVERSE-ResearchSoftware/indicators](https://github.com/EVERSE-ResearchSoftware/indicators) | The `everse-sync` CronJob populates the `dimensions` + `indicators` reference tables. | Tracks `main` | Set `indicators_ref` in `production.tfvars` (or any tfvars) to a commit SHA, then `just env=production deploy`. The next sync run fetches catalog files at exactly that ref. |
| [EVERSE-ResearchSoftware/QualityPipelines](https://github.com/EVERSE-ResearchSoftware/QualityPipelines) (`resqui`) | The assessment-runner script installs and runs `resqui` against repositories. | Latest commit on `main` | Set `RESQUI_SPEC` in `scripts/.env` (or as a shell env var) to a `git+https://...QualityPipelines.git@<sha>` URL. The script reinstalls `resqui` from that pinned ref in the venv it builds. |

Example -- the values currently in tree (refresh by re-running the
`curl ... /repos/<repo>/commits/main` checks below when bumping):

```hcl
# deployment/terraform/environments/production.tfvars
indicators_ref = "5599beb2551a05d0ee2845fcd57c6270b8085e14"
```

```bash
# scripts/.env on the prod VM
RESQUI_SPEC="git+https://github.com/EVERSE-ResearchSoftware/QualityPipelines.git@a6426f9b3b7abd3de123f8b2a85c34d84d7dfa6f"
```

To check what the upstream `main` is at right now:

```bash
curl -sS https://api.github.com/repos/EVERSE-ResearchSoftware/indicators/commits/main         | jq -r '.sha + "  " + .commit.committer.date'
curl -sS https://api.github.com/repos/EVERSE-ResearchSoftware/QualityPipelines/commits/main   | jq -r '.sha + "  " + .commit.committer.date'
```

Why this matters: upstream is free to rename indicators, change identifier
slugs, restructure JSON layouts, or remove items entirely. Without a pin
the next `everse-sync` run can suddenly make dashboards empty for
indicators the catalog no longer publishes, and `resqui` can change its
plugin set or output shape and silently break ingest. Pinning lets you
verify a release against a known catalog/runner before adopting it.

To upgrade: bump the SHA, deploy to a staging env (or your local
minikube), watch for `(unmapped indicator)` / `(unmapped dimension)`
buckets on the Catalog dashboard, and only when those are absent or
acceptable promote the SHA to `production.tfvars`.

# Just the port-forward step, bound to all interfaces:
just forward_address=0.0.0.0 port-forward

# Full deploy (re-installs the systemd unit with the 0.0.0.0 bind):
just forward_address=0.0.0.0 env=production deploy

# Reinstall just the port-forward systemd unit with the new bind address:
just forward_address=0.0.0.0 port-forward-install
```

Once the systemd-user unit has been installed with a given
`forward_address`, the unit captures that value at install time --
reinstall (or call `port-forward-install` again with the new value) to
change it.

Tear it all down:

```
just destroy-all             # destroy services + delete the minikube cluster
```

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

This sets up five role-based views (filter presets over the three dashboards) based on [RSQKit roles](https://everse.software/RSQKit/your_role):

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

## Shareable dashboard URLs

The Assessments dashboard accepts `?software=<name>` and `?project=<name>` query
parameters that pre-apply the matching native filter and hide the filter bar.
Four URL shapes produce the same view (pick whichever feels right for the
context you're sharing in):

```
https://dashverse.cloud/dashboard/assessments?software=ESMValTool   (most explicit, default share format)
https://dashverse.cloud/?software=ESMValTool                        (short)
https://dashverse.cloud/software/ESMValTool                         (path-style)
```

The same three shapes exist for projects (`?project=<name>` / `/project/<name>`).
All four route through the same handler in `frontend/app/api/routes.py`:
`_software_detail_response()` (or `_project_detail_response()`), which mints a
Superset filter-state permalink key via the existing `_filter_state_key()` helper
and embeds the dashboard with the filter pre-applied and the filter bar hidden.

Row-level security still applies. An anonymous viewer following a shareable link
to a private project's dashboard sees an empty page; an authenticated viewer who
is not the owner sees per-visibility data; the owner sees everything. So
shareable links are RLS-safe -- the URL is a navigation hint, not a backdoor.

The Share button on `/account` (for each project and each piece of software) now
generates the `/dashboard/assessments?...` form. Inline link-pills on the page
use the same long form for consistency.

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
