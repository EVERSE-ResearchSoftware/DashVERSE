# Contributing to DashVERSE

Thanks for your interest in helping out. DashVERSE is the dashboard prototype for the [EVERSE project](https://everse.software/), and contributions of all sizes are welcome: bug reports, fixes, documentation tweaks, new dashboards, schema improvements.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating you agree to its terms.

## Reporting bugs and asking questions

- Search [open issues](https://github.com/EVERSE-ResearchSoftware/DashVERSE/issues) first to avoid duplicates.
- A useful bug report includes: deployment target (local minikube, production), the command you ran, expected vs observed behaviour, and any relevant log snippets from `just logs`.
- For questions about EVERSE indicators, dimensions, or the assessment schema, the upstream repos are the right place:
  - <https://github.com/EVERSE-ResearchSoftware/indicators>
  - <https://github.com/EVERSE-ResearchSoftware/schemas>
  - <https://github.com/EVERSE-ResearchSoftware/QualityPipelines>

## Suggesting features

Open an issue describing the use case before starting work. For larger changes (a new dashboard, a new auth flow, a schema change), it is worth discussing the approach first so the work fits the rest of the system.

## Development setup

See [`docs/README.dev.md`](docs/README.dev.md) for the full setup. Short version:

1. Install OpenTofu, kubectl, helm, minikube, ansible, and Docker or Podman. If you have Nix, `nix develop` provides everything.
2. Start minikube: `minikube start --cpus='4' --memory='8g'`
3. Deploy: `just deploy` (the `env` variable defaults to `local`; use `just env=production deploy` for a real target)
4. Port-forward in a separate terminal: `just port-forward`
5. Configure dashboards: `just setup-dashboards`
6. Optional sample data: `just seed-data`

Tear down with `just destroy`, or `minikube delete` for a full reset.

## Branches and commits

- Branch from `main` with a short descriptive name like `fix-superset-init` or `add-trainer-charts`.
- Keep commits small and focused on one logical change. Avoid mixing a refactor with feature work in the same commit.
- Commit messages: lowercase, verb-first, no trailing period. For example:

  ```
  add trainer dashboard charts
  ```

- If a change touches more than five files, think about whether it should be split.

## Pull requests

1. Push your branch and open a PR against `main` describing what changed and why.
2. Link related issues with `Closes #NN`.
3. If your change affects dashboards, include a before/after screenshot or a list of affected charts.
4. CI is still being set up; until it lands, please confirm at least that `just deploy` succeeds end-to-end on a clean minikube.
5. Be patient with review. Maintainers triage on a best-effort basis.

## Code style

Match the surrounding code. Some defaults:

| Area                                         | Indent   | Notes                                                                                                                      |
| -------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------- |
| Python (backend, frontend, database)     | 4 spaces | Type hints on function signatures where they add value. Prefer `logging.getLogger(__name__)`.                              |
| SQL (deployment/database/sql)                           | 4 spaces | Uppercase keywords (`CREATE TABLE`, `SELECT`), lowercase identifiers. Brief comment for non-trivial views or triggers.     |
| Terraform (deployment/terraform/)                       | 2 spaces | HCL convention. One resource per file when it helps clarity. Use `locals {}` to reduce repetition.                         |
| Ansible (deployment/ansible/)                           | 2 spaces | Descriptive task names. The Superset role splits charts and dashboards per RSQKit role under `tasks/everse_roles/<role>/`. |
| Shell (scripts/)                             | 2 spaces | `#!/usr/bin/env bash` and `set -euo pipefail` at the top.                                                                  |

Keep diffs free of unrelated whitespace changes. Run formatters before pushing if the language has one configured locally.

## Testing

The test suite is sparse today. Where tests exist, run them with `pytest` from the relevant component directory. If you add a feature, a small unit test is appreciated even without a formal coverage target. End-to-end verification on minikube is the practical fallback for deployment changes.

## Documentation

Update the relevant doc when changing behaviour:

- Deployment changes: `docs/README.dev.md`
- Database schema: `docs/Database.md`
- API examples: `docs/API_examples.md`
- Superset and dashboards: `docs/Superset.md`, `docs/Kubernetes.md`

The repo-root `README.md` stays short on purpose; new content usually belongs under `docs/`.

## License

By contributing you agree your contributions will be licensed under the same terms as the project (see [LICENSE](LICENSE)).
