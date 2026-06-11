import os
import sys

import psycopg2

raw = os.environ.get("CHART_DATASOURCE_PAIRS", "")
pairs = [p.strip() for p in raw.split(",") if p.strip()]
if not pairs:
    sys.exit("no CHART_DATASOURCE_PAIRS provided")

conn = psycopg2.connect(
    host=os.environ["PGHOST"],
    port=int(os.environ.get("PGPORT", "5432")),
    dbname=os.environ["PGDATABASE"],
    user=os.environ["PGUSER"],
    password=os.environ["PGPASSWORD"],
)
conn.autocommit = False

changed = 0
skipped_missing = 0
with conn.cursor() as cur:
    for pair in pairs:
        if ":" not in pair:
            continue
        chart_uuid, dataset_uuid = pair.split(":", 1)
        cur.execute("SELECT id FROM tables WHERE uuid::text = %s", (dataset_uuid,))
        row = cur.fetchone()
        if not row:
            skipped_missing += 1
            print(f"SKIP chart={chart_uuid}: dataset uuid={dataset_uuid} not found in tables")
            continue
        dataset_id = row[0]
        cur.execute(
            """
            UPDATE slices
               SET datasource_id = %s,
                   datasource_type = 'table'
             WHERE uuid::text = %s
               AND (datasource_id IS DISTINCT FROM %s
                    OR datasource_type IS DISTINCT FROM 'table')
            """,
            (dataset_id, chart_uuid, dataset_id),
        )
        if cur.rowcount:
            changed += cur.rowcount
            print(f"relinked chart {chart_uuid} -> dataset id={dataset_id} ({dataset_uuid})")

conn.commit()
print(f"summary: charts relinked={changed} dataset_misses={skipped_missing}")
sys.exit(0)
