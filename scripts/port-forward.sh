#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-dashverse}"
PIDS=()

cleanup() {
    echo ""
    echo "Stopping port forwards..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    exit 0
}

trap cleanup SIGINT SIGTERM

forward() {
    local svc=$1 local_port=$2 remote_port=$3
    while true; do
        kubectl port-forward -n "$NS" "svc/$svc" "$local_port:$remote_port" 2>/dev/null || true
        sleep 2
    done
}

echo "Port forwarding to namespace: $NS"
echo "Press Ctrl+C to stop"
echo ""
echo "  PostgreSQL:      localhost:${POSTGRES_PORT:-5432}"
echo "  PostgREST:       localhost:${POSTGREST_PORT:-3000}"
echo "  PostgREST Docs:  localhost:${POSTGREST_DOCS_PORT:-3001}"
echo "  Superset:        localhost:${SUPERSET_PORT:-8088}"
echo "  Auth Service:    localhost:${AUTH_PORT:-8000}"
echo "  Auth Docs:       localhost:${AUTH_DOCS_PORT:-8001}"
echo "  Demo Portal:     localhost:${DEMO_PORT:-8080}"
echo ""

forward postgresql "${POSTGRES_PORT:-5432}" 5432 &
PIDS+=($!)

forward postgrest "${POSTGREST_PORT:-3000}" 3000 &
PIDS+=($!)

forward superset "${SUPERSET_PORT:-8088}" 8088 &
PIDS+=($!)

forward auth-service "${AUTH_PORT:-8000}" 8000 &
PIDS+=($!)

forward demo-portal "${DEMO_PORT:-8080}" 8080 &
PIDS+=($!)

forward postgrest-docs "${POSTGREST_DOCS_PORT:-3001}" 3001 &
PIDS+=($!)

forward auth-docs "${AUTH_DOCS_PORT:-8001}" 8001 &
PIDS+=($!)

wait
