import json
import os
import sys

import psycopg2

SLUGS = ["assessments", "global", "catalog"]

conn = psycopg2.connect(
    host=os.environ["PGHOST"],
    port=int(os.environ.get("PGPORT", "5432")),
    dbname=os.environ["PGDATABASE"],
    user=os.environ["PGUSER"],
    password=os.environ["PGPASSWORD"],
)
conn.autocommit = False

total_dropped = 0
with conn.cursor() as cur:
    for slug in SLUGS:
        cur.execute(
            "SELECT id, position_json FROM dashboards WHERE slug = %s",
            (slug,),
        )
        row = cur.fetchone()
        if not row:
            print(f"SKIP {slug}: dashboard not found")
            continue
        dashboard_id, position_json = row
        pos = json.loads(position_json or "{}")
        layout_uuids = {
            v.get("meta", {}).get("uuid")
            for k, v in pos.items()
            if k.startswith("CHART-")
        }
        layout_uuids.discard(None)
        if not layout_uuids:
            print(f"SKIP {slug}: no CHART-* entries in position_json")
            continue

        cur.execute(
            """
            SELECT s.id, s.slice_name
            FROM dashboard_slices ds
            JOIN slices s ON s.id = ds.slice_id
            WHERE ds.dashboard_id = %s
              AND s.uuid::text NOT IN %s
            """,
            (dashboard_id, tuple(layout_uuids)),
        )
        orphans = cur.fetchall()

        if not orphans:
            print(f"{slug}: no orphans")
            continue

        cur.execute(
            "DELETE FROM dashboard_slices "
            "WHERE dashboard_id = %s AND slice_id IN %s",
            (dashboard_id, tuple(o[0] for o in orphans)),
        )
        names = [o[1] for o in orphans]
        print(f"{slug}: dropped {len(orphans)} orphan slices: {names}")
        total_dropped += len(orphans)

conn.commit()
print(f"total orphans dropped: {total_dropped}")
sys.exit(0)
