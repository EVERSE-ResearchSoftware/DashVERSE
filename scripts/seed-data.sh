#!/usr/bin/env bash
set -euo pipefail

# populate seed data from EVERSE TechRadar
# fetches software tools and generates sample assessments

NAMESPACE="${1:-dashverse}"
TECHRADAR_URL="https://api.github.com/repos/EVERSE-ResearchSoftware/TechRadar/contents/data/software-tools"
RAW_BASE="https://raw.githubusercontent.com/EVERSE-ResearchSoftware/TechRadar/main/data/software-tools"

OUTPUT_DIR="/tmp/dashverse-seed"
mkdir -p "$OUTPUT_DIR"

echo "Fetching software list from TechRadar..."
curl -s "$TECHRADAR_URL" | jq -r '.[].name' | grep '\.json$' > "$OUTPUT_DIR/software-list.txt"

TOTAL=$(wc -l < "$OUTPUT_DIR/software-list.txt")
echo "Found $TOTAL software tools"

# fetch first 20 software tools for seed data
head -20 "$OUTPUT_DIR/software-list.txt" > "$OUPUT_DIR/selected.txt"

echo "Downloading software metadata..."
mkdir -p "$OUTPUT_DIR/software"
while read -r file; do
    name="${file%.json}"
    curl -s "$RAW_BASE/$file" -o "$OUTPUT_DIR/software/$file"
done < "$OUTPUT_DIR/selected.txt"

generate_sql() {
    echo "SET search_path TO api, public;"
    echo ""

    # software entries
    echo "-- software from TechRadar"
    for f in "$OUTPUT_DIR/software"/*.json; do
        id=$(jq -r '.["@id"] // empty' "$f")
        name=$(jq -r '.name // empty' "$f")
        desc=$(jq -r '.description // empty' "$f" | sed "s/'/''/g")
        url=$(jq -r '.url // empty' "$f")
        license=$(jq -r '.license // empty' "$f")
        langs=$(jq -c '.appliesToProgrammingLanguage // []' "$f")

        if [[ -n "$name" ]]; then
            echo "INSERT INTO software (identifier, name, description, homepage_url, license, programming_language)"
            echo "VALUES ('$name', '$name', '$desc', '$url', '$license', ARRAY(SELECT jsonb_array_elements_text('$langs'::jsonb)))"
            echo "ON CONFLICT (identifier) DO UPDATE SET"
            echo "  description = EXCLUDED.description,"
            echo "  homepage_url = EXCLUDED.homepage_url,"
            echo "  updated_at = CURRENT_TIMESTAMP;"
            echo ""
        fi
    done

    # sample assessments
    echo "-- sample assessments"
    local count=0
    local indicators=("has_ci-tests" "has_releases" "descriptive_metadata" "dependency_management" "has_published_package" "has_no_linting_issues")

    for f in "$OUTPUT_DIR/software"/*.json; do
        name=$(jq -r '.name // empty' "$f")
        url=$(jq -r '.url // empty' "$f")

        if [[ -z "$name" ]]; then
            continue
        fi

        count=$((count + 1))
        local month=$((1 + (count % 6)))
        local day=$((1 + (count * 3 % 28)))
        local date=$(printf "2025-%02d-%02dT10:00:00Z" "$month" "$day")

        # generate checks with varying results
        local checks="["
        local first=true
        for ind in "${indicators[@]}"; do
            # vary pass/fail based on hash of name+indicator
            local hash=$(echo -n "${name}${ind}" | md5sum | cut -c1-2)
            local hash_num=$((16#$hash))
            local status="Pass"
            if (( hash_num % 5 == 0 )); then
                status="Fail"
            fi

            if [[ "$first" != "true" ]]; then
                checks+=","
            fi
            checks+="{\"@type\":\"Check\",\"assessesIndicator\":{\"@id\":\"$ind\"},\"status\":{\"@id\":\"$status\"}}"
            first=false
        done
        checks+="]"

        cat <<EOF
INSERT INTO assessment_raw (payload, created_at) VALUES
('{
  "@context": "https://w3id.org/everse/assessment",
  "@type": "SoftwareAssessment",
  "@id": "urn:assessment:$name-seed",
  "dateCreated": "$date",
  "assessedSoftware": {
    "@type": "SoftwareSourceCode",
    "name": "$name",
    "url": "$url"
  },
  "checks": $checks
}'::jsonb, '$date');

EOF
    done
}

if [[ "${2:-}" == "--apply" ]]; then
    echo "Generating and importing seed data..."
    POD=$(kubectl get pod -n "$NAMESPACE" -l component=postgresql -o jsonpath='{.items[0].metadata.name}')
    generate_sql | kubectl exec -i -n "$NAMESPACE" "$POD" -- psql -U dashverse -d dashverse
    echo "Seed data imported: $(wc -l < "$OUTPUT_DIR/selected.txt") software tools with assessments"
else
    generate_sql
fi
