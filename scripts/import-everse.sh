#!/usr/bin/env bash
set -euo pipefail

# import EVERSE data to database
# reads JSON files from sync output and generates SQL

INPUT_DIR="${1:-/tmp/everse-sync}"
NAMESPACE="${2:-dashverse}"

if [[ ! -d "$INPUT_DIR/dimensions" ]]; then
    echo "Error: Run sync-everse.sh first" >&2
    exit 1
fi

generate_sql() {
    echo "SET search_path TO api, public;"
    echo ""

    # dimensions
    echo "-- dimensions"
    for f in "$INPUT_DIR/dimensions"/*.json; do
        id=$(jq -r '.["@id"] // .identifier // empty' "$f")
        name=$(jq -r '.name // empty' "$f")
        desc=$(jq -r '.description // empty' "$f" | sed "s/'/''/g")
        abbrev=$(jq -r '.abbreviation // empty' "$f")
        source=$(jq -c '.source // {}' "$f")

        if [[ -n "$id" && -n "$name" ]]; then
            echo "INSERT INTO dimensions (identifier, name, description, status, source)"
            echo "VALUES ('$abbrev', '$name', '$desc', 'Active', '$source'::jsonb)"
            echo "ON CONFLICT (identifier) DO UPDATE SET"
            echo "  name = EXCLUDED.name,"
            echo "  description = EXCLUDED.description,"
            echo "  source = EXCLUDED.source,"
            echo "  updated_at = CURRENT_TIMESTAMP;"
            echo ""
        fi
    done

    # indicators
    echo "-- indicators"
    for f in "$INPUT_DIR/indicators"/*.json; do
        id=$(jq -r '.["@id"] // .identifier // empty' "$f")
        name=$(jq -r '.name // empty' "$f")
        desc=$(jq -r '.description // empty' "$f" | sed "s/'/''/g")
        abbrev=$(jq -r '.abbreviation // empty' "$f")
        status=$(jq -r '.status // "Active"' "$f")
        dim=$(jq -r '.qualityDimension // empty' "$f")
        contact=$(jq -c '.contact // .contactPoint // {}' "$f")
        source=$(jq -c '.source // {}' "$f")

        if [[ -n "$id" && -n "$name" ]]; then
            echo "INSERT INTO indicators (identifier, name, description, status, quality_dimension, contact, source)"
            echo "VALUES ('$abbrev', '$name', '$desc', '$status', '$dim', '$contact'::jsonb, '$source'::jsonb)"
            echo "ON CONFLICT (identifier) DO UPDATE SET"
            echo "  name = EXCLUDED.name,"
            echo "  description = EXCLUDED.description,"
            echo "  status = EXCLUDED.status,"
            echo "  quality_dimension = EXCLUDED.quality_dimension,"
            echo "  contact = EXCLUDED.contact,"
            echo "  source = EXCLUDED.source,"
            echo "  updated_at = CURRENT_TIMESTAMP;"
            echo ""
        fi
    done
}

if [[ "${3:-}" == "--apply" ]]; then
    generate_sql | kubectl exec -i -n "$NAMESPACE" deploy/postgresql -- psql -U dashverse -d dashverse
    echo "Import complete"
else
    generate_sql
fi
