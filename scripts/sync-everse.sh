#!/usr/bin/env bash
set -euo pipefail

# sync indicators and dimensions from EVERSE repository

GITHUB_RAW="https://raw.githubusercontent.com/EVERSE-ResearchSoftware/indicators/main"
GITHUB_API="https://api.github.com/repos/EVERSE-ResearchSoftware/indicators/contents"
OUTPUT_DIR="${1:-/tmp/everse-sync}"
MAX_RETRIES=3

mkdir -p "$OUTPUT_DIR/dimensions" "$OUTPUT_DIR/indicators"

fetch_with_retry() {
    local url="$1"
    local output="$2"
    local attempt=1
    local delay=1

    while [[ $attempt -le $MAX_RETRIES ]]; do
        if curl -sfL "$url" -o "$output"; then
            return 0
        fi
        echo "Retry $attempt/$MAX_RETRIES for $url" >&2
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    return 1
}

echo "Fetching dimensions..."
DIMS=$(curl -sf "$GITHUB_API/dimensions" | jq -r '.[].name | select(endswith(".json"))')
for dim in $DIMS; do
    echo "  $dim"
    fetch_with_retry "$GITHUB_RAW/dimensions/$dim" "$OUTPUT_DIR/dimensions/$dim"
done

echo "Fetching indicators..."
INDS=$(curl -sf "$GITHUB_API/indicators" | jq -r '.[].name | select(endswith(".json"))')
for ind in $INDS; do
    echo "  $ind"
    fetch_with_retry "$GITHUB_RAW/indicators/$ind" "$OUTPUT_DIR/indicators/$ind"
done

echo ""
echo "Downloaded to $OUTPUT_DIR"
echo "Dimensions: $(ls "$OUTPUT_DIR/dimensions" | wc -l)"
echo "Indicators: $(ls "$OUTPUT_DIR/indicators" | wc -l)"
