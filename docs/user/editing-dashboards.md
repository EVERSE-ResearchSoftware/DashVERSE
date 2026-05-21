# Editing dashboards in Superset

For users who want to customise a chart or dashboard from the UI without
touching the deployment.

## Logging in

Superset is at the URL your administrator gave you. Locally that's
<http://localhost:8088/> after `just port-forward`; log in as `admin`
with the password from `just show-access`.

## Editing an existing chart

Click **Charts** in the top nav, find your chart, and open it via the
title or the **Actions -> Edit** menu. Tweak metrics, groupings, or the
visualization type from the controls on the left, then **Save** to
overwrite or **Save As** for a copy.

## Editing an existing dashboard

**Dashboards** -> open it -> **Edit dashboard** (top right). Drag charts
to rearrange, resize from the corners, click the gear icon for
dashboard-level settings, click the menu on a chart to remove it. Save
when you're done.

To add a dashboard-level filter (e.g. *filter by software project*),
click the filter icon in the left sidebar in edit mode and use **+ Add
/ Edit filters**.

## Creating a new chart

**Charts -> + CHART**, pick a dataset (`assessments_detailed`,
`checks_detailed`, `dimension_coverage`, ...), pick a visualization
type, drag fields into "Dimensions" and "Metrics", tune the options on
the right, and **Save**. Add a 1-2-sentence description in the chart
properties so other people see context on hover.

Add it to a dashboard either from the chart editor (**Save -> Save
chart and add to existing dashboard**) or from inside the dashboard
editor (**+ Add charts** in the left sidebar).

## How edits reach the project

Anything you change in the UI lives only on this Superset instance until
a developer runs `just export-superset-assets` and commits the new
YAMLs. Until then your changes are not version-controlled and will
disappear if the cluster is reset. If you want a change shipped, ping a
developer or open a GitHub issue.

## Useful upstream documentation

- Creating dashboards (10-minute walkthrough):
  <https://superset.apache.org/docs/creating-charts-dashboards/creating-your-first-dashboard/>
- Chart types reference:
  <https://superset.apache.org/docs/configuration/chart-options/>
- Native filters guide:
  <https://superset.apache.org/docs/creating-charts-dashboards/dashboard-filters/>
- SQL Lab (run ad-hoc queries):
  <https://superset.apache.org/docs/using-superset/sql-lab/>
