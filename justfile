
env := "local"
ns := "dashverse"

forward_address := "127.0.0.1"

default:
    @just --list

deploy: build-backend build-frontend
    cd terraform && tofu init && tofu apply -var-file="environments/{{env}}.tfvars" -auto-approve

destroy:
    cd terraform && tofu destroy -var-file="environments/{{env}}.tfvars" -auto-approve

destroy-all: destroy
    minikube delete --all

status:
    kubectl get all -n {{ns}}

port-forward:
    #!/usr/bin/env bash
    set -uo pipefail
    declare -A SERVICES=(
        [postgresql]=5432
        [postgrest]=3000
        [superset]=8088
        [backend]=8000
        [frontend]=8080
        [postgrest-docs]=3001
        [backend-docs]=8001
    )
    pids=()
    cleanup() {
        echo
        echo "stopping port-forwards..."
        for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
        wait 2>/dev/null || true
        exit 0
    }
    trap cleanup INT TERM
    pf() {
        local svc=$1 port=$2
        while true; do
            kubectl port-forward --address {{forward_address}} -n {{ns}} \
                "svc/$svc" "$port:$port" 2>&1 \
                | sed -u "s/^/[$svc] /" || true
            echo "[$svc] disconnected -- retrying in 2s"
            sleep 2
        done
    }
    for svc in "${!SERVICES[@]}"; do
        pf "$svc" "${SERVICES[$svc]}" &
        pids+=($!)
        echo "  $svc -> {{forward_address}}:${SERVICES[$svc]}  (pid $!)"
    done
    echo
    echo "forwarding ${#pids[@]} services on {{forward_address}}. Ctrl+C to stop."
    wait

logs:
    kubectl logs -n {{ns}} -l app=dashverse --all-containers -f

logs-postgres:
    kubectl logs -n {{ns}} -l component=postgresql -f

logs-postgrest:
    kubectl logs -n {{ns}} -l component=postgrest -f

logs-superset:
    kubectl logs -n {{ns}} -l app.kubernetes.io/name=superset -f

logs-backend:
    kubectl logs -n {{ns}} -l app=backend -f

logs-frontend:
    kubectl logs -n {{ns}} -l app=frontend -f

clean:
    cd terraform && rm -rf .terraform .terraform.lock.hcl .tofu

sync:
    cd ansible && \
        ansible-playbook -i inventory/{{env}}.yml playbooks/sync_everse.yml --tags fetch

sync-apply:
    cd ansible && \
        ansible-playbook -i inventory/{{env}}.yml playbooks/sync_everse.yml

sync-trigger:
    kubectl create job -n {{ns}} --from=cronjob/everse-sync everse-sync-manual-$(date +%s)

jwt username password:
    @curl -sSf -X POST http://localhost:8000/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"{{username}}","password":"{{password}}"}' \
        | jq -r .access_token

build-backend:
    if [ "{{env}}" = "local" ]; then \
        minikube image build -t dashverse/backend:latest backend/; \
    else \
        docker build -t dashverse/backend:latest backend/; \
    fi

build-frontend:
    if [ "{{env}}" = "local" ]; then \
        minikube image build -t dashverse/frontend:latest frontend/; \
    else \
        docker build -t dashverse/frontend:latest frontend/; \
    fi

setup-dashboards:
    cd ansible && \
    DATABASE_PASSWORD=$(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.postgres-password}' | base64 -d) \
    SUPERSET_PASSWORD=$(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.superset-admin-password}' | base64 -d) \
    ansible-playbook -i inventory/{{env}}.yml playbooks/configure_superset.yml

export-superset-assets:
    @OUT_DIR=ansible/files/superset_assets && \
    TMP_ZIP=/tmp/dashverse-assets.zip && \
    TMP_EXTRACT=/tmp/dashverse-assets-extract && \
    echo "Exporting from deploy/superset" && \
    rm -rf $OUT_DIR/charts $OUT_DIR/dashboards $OUT_DIR/datasets $OUT_DIR/databases $OUT_DIR/metadata.yaml $TMP_EXTRACT && \
    mkdir -p $OUT_DIR $TMP_EXTRACT && \
    kubectl exec -n {{ns}} -c superset deploy/superset -- bash -c "superset export-dashboards -f $TMP_ZIP >/dev/null 2>&1" && \
    kubectl exec -n {{ns}} -c superset deploy/superset -- base64 -w0 $TMP_ZIP 2>/dev/null | base64 -d > $TMP_ZIP && \
    kubectl exec -n {{ns}} -c superset deploy/superset -- rm -f $TMP_ZIP 2>/dev/null && \
    unzip -q $TMP_ZIP -d $TMP_EXTRACT && \
    mv $TMP_EXTRACT/*/* $OUT_DIR/ && \
    rm -rf $TMP_ZIP $TMP_EXTRACT && \
    echo "Exported $(find $OUT_DIR -name '*.yaml' | wc -l) YAML files to $OUT_DIR"

seed-data:
    cd ansible && \
        ansible-playbook -i inventory/{{env}}.yml playbooks/seed_data.yml

show-access:
    @echo "=== DashVERSE credentials ==="
    @echo "PostgreSQL:"
    @echo "  user:     dashverse"
    @echo "  password: $(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.postgres-password}' | base64 -d)"
    @echo "  host:     postgresql.{{ns}}.svc.cluster.local:5432"
    @echo "  database: dashverse"
    @echo ""
    @echo "Superset:"
    @echo "  user:     admin"
    @echo "  password: $(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.superset-admin-password}' | base64 -d)"
    @echo "  url:      http://localhost:8088 (via 'just port-forward')"
