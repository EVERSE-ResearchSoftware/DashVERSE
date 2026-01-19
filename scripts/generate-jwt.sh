#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-dashverse}"
ROLE="${2:-web_user}"
EXPIRY="${3:-3600}"

# get jwt secret from k8s
SECRET_NAME="dashverse-secrets"
JWT_SECRET=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath='{.data.jwt-secret}' | base64 -d)

if [[ -z "$JWT_SECRET" ]]; then
    echo "Error: JWT secret not found" >&2
    exit 1
fi

# create jwt header
HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64 -w0 | tr '+/' '-_' | tr -d '=')

# create payload
NOW=$(date +%s)
EXP=$((NOW + EXPIRY))
PAYLOAD=$(echo -n "{\"role\":\"$ROLE\",\"iat\":$NOW,\"exp\":$EXP}" | base64 -w0 | tr '+/' '-_' | tr -d '=')

# create signature
SIGNATURE=$(echo -n "${HEADER}.${PAYLOAD}" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64 -w0 | tr '+/' '-_' | tr -d '=')

TOKEN="${HEADER}.${PAYLOAD}.${SIGNATURE}"

echo ""
echo "JWT token generated"
echo ""
echo "Role: $ROLE"
echo "Expires: $(date -d "@$EXP")"
echo ""
echo "Token:"
echo "$TOKEN"
echo ""
echo "Usage:"
echo "  curl -H 'Authorization: Bearer $TOKEN' http://localhost:3000/assessment"
