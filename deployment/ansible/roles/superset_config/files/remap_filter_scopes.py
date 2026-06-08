
import psycopg2
import json
import os
import sys

conn = psycopg2.connect(
    host=os.environ["PGHOST"],
    port=int(os.environ.get("PGPORT", "5432")),
    dbname=os.environ["PGDATABASE"],
    user=os.environ["PGUSER"],
    password=os.environ["PGPASSWORD"],
)
cur = conn.cursor()

cur.execute(
    "SELECT id, slug, dashboard_title, position_json, json_metadata "
    "FROM dashboards WHERE slug IS NOT NULL ORDER BY id"
)

total_changed = 0
for did, slug, title, pos_json, meta_json in cur.fetchall():
    pos = json.loads(pos_json or "{}")
    meta = json.loads(meta_json or "{}")

    live_ids = set()
    for k, v in pos.items():
        if isinstance(v, dict) and v.get("type") == "CHART":
            live_ids.add(v["meta"]["chartId"])
    if not live_ids:
        continue

    changed = False

    for nf in meta.get("native_filter_configuration", []) or []:
        old = list(nf.get("chartsInScope", []))
        scope = nf.get("scope") or {}
        old_excluded = list(scope.get("excluded", []))
        new_excluded = sorted(set(old_excluded) & live_ids)
        new_in_scope = sorted(live_ids - set(new_excluded))
        if sorted(old) != new_in_scope:
            nf["chartsInScope"] = new_in_scope
            changed = True
        if sorted(old_excluded) != new_excluded:
            scope["excluded"] = new_excluded
            nf["scope"] = scope
            changed = True

    cc = meta.get("chart_configuration", {}) or {}
    desired_keys = set(str(c) for c in live_ids)
    if set(cc.keys()) != desired_keys:
        new_cc = {}
        for cid in sorted(live_ids):
            others = sorted(live_ids - {cid})
            new_cc[str(cid)] = {
                "id": cid,
                "crossFilters": {"scope": "global", "chartsInScope": others},
            }
        meta["chart_configuration"] = new_cc
        changed = True

    exp = meta.get("expanded_slices", {}) or {}
    if exp and set(exp.keys()) != desired_keys:
        meta["expanded_slices"] = {str(cid): True for cid in sorted(live_ids)}
        changed = True

    if changed:
        cur.execute(
            "UPDATE dashboards SET json_metadata = %s WHERE id = %s",
            (json.dumps(meta), did),
        )
        print(f"  {slug}: remapped ({len(live_ids)} live charts)")
        total_changed += 1
    else:
        print(f"  {slug}: already correct")

conn.commit()
cur.close()
conn.close()
print(f"remapped {total_changed} dashboards")
