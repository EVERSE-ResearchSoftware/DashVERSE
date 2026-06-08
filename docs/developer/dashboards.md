# Adding charts and dashboards

The recommended workflow is: design in the Superset UI, export the
result to YAML, commit it. The Ansible role re-imports those YAMLs on
every `just setup-dashboards` run, so the files in
`deployment/ansible/files/superset_assets/` are the source of truth for what each
dashboard contains.

For an end-user walk-through of the Superset UI itself, see
[`../user/editing-dashboards.md`](../user/editing-dashboards.md).

## Prerequisites

You need a running cluster reachable on localhost
(`just deploy && just port-forward`), the Superset admin password
(`just show-access`), and the dataset you want to chart against already
registered. The dataset list lives in
`deployment/ansible/roles/superset_config/defaults/main.yml`.

## Adding a chart to an existing role dashboard

Open Superset, log in as `admin`, go to **Charts -> + CHART**, and build
your chart in the usual way -- pick a dataset, choose a viz type, set
metrics and groupings, save with a clear name. Add a 1-2-sentence
description in the chart's edit dialog so other users see context on
hover; aim for "what it shows + how to read it" like the existing
charts.

Then open the role dashboard (e.g. **Policy Maker**), click **Edit
dashboard**, drag your new chart into the layout, and save.

Refresh the YAML and commit:

```
just export-superset-assets
git add deployment/ansible/files/superset_assets/
git commit -m "add <chart name> to <role> dashboard"
```

The next `just setup-dashboards` re-imports the YAML and your changes
are live.

## Adding a new dataset

Datasets sit between Superset and the underlying SQL views, so add the
view first. Drop the `CREATE VIEW` into
`deployment/database/sql/schema/006_create_views.sql` with a matching `GRANT` in
`007_grant_permissions.sql`, then either redeploy the database or apply
the file in place:

```
kubectl exec -i -n dashverse deploy/postgresql \
    -- psql -U dashverse -d dashverse \
    < deployment/database/sql/schema/006_create_views.sql
```

Then add an entry under `datasets:` in
`deployment/ansible/roles/superset_config/defaults/main.yml`:

```yaml
- name: my_new_view
  table: my_new_view
  schema: "{{ database_schema }}"
```

`just setup-dashboards` registers the dataset with Superset and grants
the Public role read access.

## Adding a new role dashboard

Pick a stable lower-snake-case key (`data_steward`) and matching
kebab-case slug (`data-steward`). Create the dashboard in Superset with
that slug, add the charts you want, configure native filters (Software,
Creator, Dimension, ...), and export.

Then wire the role into the codebase:

- Add the key to `dashboard_role_keys` in
  `deployment/ansible/roles/superset_config/defaults/main.yml`.
- Add the role to the `DASHBOARDS` dict in `frontend/app/api/routes.py`,
  including its `rsqkit_url`.
- Add a nav link in `frontend/app/templates/base.html`.

Re-run `just setup-dashboards` and `just build-frontend` and verify in
the browser.

## Editing an existing chart or dashboard

Edit in the Superset UI, save, run `just export-superset-assets`,
commit the diff. The YAML in git always matches the live cluster.

## Troubleshooting

- *Error loading chart datasources* -- the Public role doesn't have
  access to the dataset. Re-run `just setup-dashboards`; the
  `permissions.yml` task grants Public access to every dataset listed
  under `datasets:`.
- *No results were returned for this query* -- the underlying view
  returns zero rows. Usually the indicator JOIN doesn't match for the
  current data. Run the view query in Superset SQL Lab to confirm; see
  [`../Database.md`](../Database.md) for the JOIN structure.
- *Native filters show only `NULL`* -- the column being filtered is
  NULL for every row, which usually traces back to the same indicator
  or dimension JOIN issue.
- *Layout looks wrong after redeploy* -- the YAML on disk is stale. Run
  `just export-superset-assets` again and recommit.

## See also

- [`../Superset.md`](../Superset.md) -- datasets, views, metrics
- [`../Database.md`](../Database.md) -- schema reference
- [`../user/editing-dashboards.md`](../user/editing-dashboards.md) -- end-user UI walkthrough
- Superset's own dashboarding guide:
  <https://superset.apache.org/docs/creating-charts-dashboards/creating-your-first-dashboard/>
