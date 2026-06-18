
env := "local"
ns := "dashverse"

forward_address := "127.0.0.1"

default:
    @just --list

deploy: build-backend build-frontend
    cd deployment/terraform && tofu init && tofu apply -var-file="environments/{{env}}.tfvars" -auto-approve
    @just port-forward-install || echo "warning: skipped systemd port-forward install (no systemd-user available)"

destroy:
    cd deployment/terraform && tofu destroy -var-file="environments/{{env}}.tfvars" -auto-approve

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

port-forward-install:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v systemctl >/dev/null 2>&1; then
        echo "systemctl not found -- skipping (no systemd on this host)"
        exit 0
    fi
    if ! systemctl --user --version >/dev/null 2>&1; then
        echo "systemd-user not available -- skipping"
        exit 0
    fi
    PROJECT_DIR="$(pwd)"
    JUST_BIN="$(command -v just)"
    UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    UNIT_PATH="${UNIT_DIR}/dashverse-port-forward.service"
    mkdir -p "${UNIT_DIR}"
    sed \
        -e "s|@PROJECT_DIR@|${PROJECT_DIR}|g" \
        -e "s|@JUST_BIN@|${JUST_BIN}|g" \
        -e "s|@PATH@|${PATH}|g" \
        -e "s|@HOME@|${HOME}|g" \
        -e "s|@KUBECONFIG@|${KUBECONFIG:-$HOME/.kube/config}|g" \
        deployment/systemd/dashverse-port-forward.service.template \
        > "${UNIT_PATH}"
    if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$(id -un)" >/dev/null 2>&1 || true
    fi
    systemctl --user daemon-reload
    systemctl --user enable --now dashverse-port-forward.service
    echo "installed ${UNIT_PATH}"
    echo "status:  just port-forward-status"
    echo "logs:    just port-forward-logs"

port-forward-status:
    systemctl --user status dashverse-port-forward.service --no-pager || true

port-forward-logs:
    journalctl --user -u dashverse-port-forward.service -f

port-forward-uninstall:
    -systemctl --user disable --now dashverse-port-forward.service 2>/dev/null
    rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/dashverse-port-forward.service"
    systemctl --user daemon-reload 2>/dev/null || true
    @echo "removed"

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
    cd deployment/terraform && rm -rf .terraform .terraform.lock.hcl .tofu

sync:
    cd deployment/ansible && \
        ansible-playbook -i inventory/{{env}}.yml playbooks/sync_everse.yml --tags fetch

sync-apply:
    cd deployment/ansible && \
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
    cd deployment/ansible && \
    DATABASE_PASSWORD=$(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.postgres-password}' | base64 -d) \
    SUPERSET_PASSWORD=$(kubectl get secret {{ns}}-secrets -n {{ns}} -o jsonpath='{.data.superset-admin-password}' | base64 -d) \
    ansible-playbook -i inventory/{{env}}.yml playbooks/configure_superset.yml

export-superset-assets:
    @OUT_DIR=deployment/ansible/files/superset_assets && \
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
    cd deployment/ansible && \
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
