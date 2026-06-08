# Superset assets

YAML exports of the role dashboards, charts, datasets, and database
connection. The Ansible role re-imports them on every
`just setup-dashboards` run, so this folder is the source of truth.

To refresh after editing in the UI: `just port-forward` (separate
terminal) then `just export-superset-assets`. Each YAML file maps 1:1
to a Superset object via UUID; prefer editing in the UI and re-exporting
over hand-edits.

See [`docs/developer/dashboards.md`](../../../docs/developer/dashboards.md)
for the full workflow.
