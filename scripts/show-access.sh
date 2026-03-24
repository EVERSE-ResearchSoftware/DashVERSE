#!/bin/bash
# Retrieve DashVERSE service credentials from Kubernetes secrets

set -e

NAMESPACE="${NAMESPACE:-dashverse}"
SECRET_NAME="${SECRET_NAME:-dashverse-secrets}"

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "\n${GREEN}=== $1 ===${NC}\n"
}

print_credential() {
    local name=$1
    local value=$2
    printf "  %-25s %s\n" "$name:" "$value"
}

# check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

# check namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: Namespace '$NAMESPACE' not found${NC}"
    echo "Make sure DashVERSE is deployed first."
    exit 1
fi

# check secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo -e "${RED}Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'${NC}"
    exit 1
fi

print_header "DashVERSE Credentials"

# postgres
echo -e "${YELLOW}PostgreSQL${NC}"
pg_pass=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.postgres-password}' | base64 -d)
print_credential "Username" "dashverse"
print_credential "Password" "$pg_pass"
print_credential "Host" "postgresql.$NAMESPACE.svc.cluster.local"
print_credential "Port" "5432"
print_credential "Database" "dashverse"

echo ""

# superset
echo -e "${YELLOW}Superset${NC}"
superset_pass=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.superset-admin-password}' | base64 -d)
print_credential "Username" "admin"
print_credential "Password" "$superset_pass"
print_credential "URL" "http://localhost:8088 (via port-forward)"

echo ""

# jwt secret (for reference)
echo -e "${YELLOW}JWT Secret${NC}"
jwt_secret=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.jwt-secret}' | base64 -d)
print_credential "Secret" "$jwt_secret"

echo ""
echo -e "${GREEN}Tip:${NC} Run 'make port-forward' to access services locally"
