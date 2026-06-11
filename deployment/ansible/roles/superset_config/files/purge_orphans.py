import os
import sys

import psycopg2

expected_dashboards = {
    u.strip() for u in os.environ.get("EXPECTED_DASHBOARD_UUIDS", "").split(",") if u.strip()
}
expected_charts = {
    u.strip() for u in os.environ.get("EXPECTED_CHART_UUIDS", "").split(",") if u.strip()
}
expected_datasets = {
    n.strip() for n in os.environ.get("EXPECTED_DATASET_NAMES", "").split(",") if n.strip()
}

if not expected_dashboards or not expected_charts or not expected_datasets:
    sys.exit(
        "missing EXPECTED_DASHBOARD_UUIDS, EXPECTED_CHART_UUIDS, or EXPECTED_DATASET_NAMES env vars"
    )

conn = psycopg2.connect(
    host=os.environ["PGHOST"],
    port=int(os.environ.get("PGPORT", "5432")),
    dbname=os.environ["PGDATABASE"],
    user=os.environ["PGUSER"],
    password=os.environ["PGPASSWORD"],
)
conn.autocommit = False

dropped_dashboards = 0
dropped_charts = 0
dropped_datasets = 0

with conn.cursor() as cur:
    cur.execute("SELECT id, uuid::text, dashboard_title, slug FROM dashboards")
    for did, duuid, title, slug in cur.fetchall():
        if duuid in expected_dashboards:
            continue
        cur.execute("DELETE FROM embedded_dashboards WHERE dashboard_id = %s", (did,))
        cur.execute("DELETE FROM dashboard_slices WHERE dashboard_id = %s", (did,))
        cur.execute("DELETE FROM dashboard_user WHERE dashboard_id = %s", (did,))
        cur.execute("DELETE FROM dashboard_roles WHERE dashboard_id = %s", (did,))
        cur.execute(
            "DELETE FROM tagged_object WHERE object_id = %s AND object_type = 'dashboard'",
            (did,),
        )
        cur.execute("DELETE FROM dashboards WHERE id = %s", (did,))
        print(f"dropped dashboard id={did} slug={slug!r} title={title!r}")
        dropped_dashboards += 1

    cur.execute("SELECT id, uuid::text, slice_name FROM slices")
    for sid, suuid, name in cur.fetchall():
        if suuid in expected_charts:
            continue
        cur.execute("DELETE FROM dashboard_slices WHERE slice_id = %s", (sid,))
        cur.execute("DELETE FROM slice_user WHERE slice_id = %s", (sid,))
        cur.execute(
            "DELETE FROM tagged_object WHERE object_id = %s AND object_type = 'chart'",
            (sid,),
        )
        cur.execute("DELETE FROM slices WHERE id = %s", (sid,))
        print(f"dropped chart id={sid} name={name!r}")
        dropped_charts += 1

    cur.execute("SELECT id, table_name FROM tables")
    for tid, tname in cur.fetchall():
        if tname in expected_datasets:
            continue
        cur.execute(
            "DELETE FROM slices WHERE datasource_id = %s AND datasource_type = 'table'",
            (tid,),
        )
        cur.execute("DELETE FROM sql_metrics WHERE table_id = %s", (tid,))
        cur.execute("DELETE FROM table_columns WHERE table_id = %s", (tid,))
        cur.execute("DELETE FROM tables WHERE id = %s", (tid,))
        print(f"dropped dataset id={tid} table_name={tname!r}")
        dropped_datasets += 1

conn.commit()
print(
    f"summary: dashboards dropped={dropped_dashboards} "
    f"charts dropped={dropped_charts} datasets dropped={dropped_datasets}"
)
sys.exit(0)
