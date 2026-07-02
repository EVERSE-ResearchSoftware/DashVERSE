
env := "local"
ns := "dashverse"

forward_address := "127.0.0.1"

default:
    @just --list

check-deps:
    #!/usr/bin/env bash
    set -uo pipefail
    required=(tofu kubectl helm minikube ansible-playbook curl jq base64)
    missing=()
    for cmd in "${required[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
        missing+=("docker or podman")
    fi
    if [ "${#missing[@]}" -gt 0 ]; then
        echo "missing required tools:" >&2
        for m in "${missing[@]}"; do echo "  - $m" >&2; done
        echo >&2
        echo "install them and re-run; if you use the project flake, try:" >&2
        echo "  nix develop --command just <recipe>" >&2
        exit 1
    fi
    echo "ok: all required tools on PATH ($(printf '%s ' "${required[@]}") + container runtime)"

check-minikube:
    #!/usr/bin/env bash
    set -uo pipefail
    if [ "${SKIP_MINIKUBE:-0}" = "1" ]; then
        echo "skip: SKIP_MINIKUBE=1, not touching minikube"
        exit 0
    fi
    if ! command -v minikube >/dev/null 2>&1; then
        echo "error: minikube not found on PATH" >&2
        echo "  install it, or run inside 'nix develop', or set SKIP_MINIKUBE=1" >&2
        exit 1
    fi
    if minikube status >/dev/null 2>&1; then
        echo "ok: minikube cluster running"
    else
        echo "minikube is not running -- starting it..."
        minikube start
    fi

deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    TOTAL=10
    VERBOSE="${VERBOSE:-0}"
    LOG_DIR="$(mktemp -d /tmp/dashverse-deploy-XXXXXX)"
    trap 'rm -rf "$LOG_DIR"' EXIT
    STEP_START=0

    step() {
        local n=$1; local desc=$2
        echo
        echo "==> [$n/$TOTAL] $desc"
        STEP_START=$(date +%s)
    }

    if [ -t 1 ]; then C_OK=$'\033[32m'; C_RESET=$'\033[0m'; else C_OK=""; C_RESET=""; fi
    if [ -t 2 ]; then C_FAIL=$'\033[31m'; else C_FAIL=""; fi
    done_ok() {
        local elapsed=$(( $(date +%s) - STEP_START ))
        echo "    ${C_OK}[ok]${C_RESET} (${elapsed}s)"
    }

    fail_step() {
        local elapsed=$(( $(date +%s) - STEP_START ))
        echo "    ${C_FAIL}[failed]${C_RESET} after ${elapsed}s" >&2
    }

    run() {
        local label=$1; shift
        local log="$LOG_DIR/${label}.log"
        if [ "$VERBOSE" = "1" ]; then
            if ! "$@"; then fail_step; return 1; fi
        else
            if ! "$@" >"$log" 2>&1; then
                fail_step
                echo "    last 60 lines of $log:" >&2
                tail -n 60 "$log" >&2
                return 1
            fi
        fi
        done_ok
    }

    step 1 "Verifying required tools are on PATH"
    run check-deps just check-deps

    step 2 "Verifying minikube cluster (starting it if necessary)"
    run check-minikube just check-minikube

    step 3 "Building backend image into minikube's runtime"
    run build-backend just build-backend

    step 4 "Building frontend image into minikube's runtime"
    run build-frontend just build-frontend

    step 5 "Applying Terraform infrastructure (databases, services, schema-apply Job)"
    if [ "$VERBOSE" = "1" ]; then
        ( cd deployment/terraform && tofu init && tofu apply -var-file="environments/{{env}}.tfvars" -auto-approve ) || { fail_step; exit 1; }
        done_ok
    else
        if ! ( cd deployment/terraform && tofu init -no-color && tofu apply -no-color -var-file="environments/{{env}}.tfvars" -auto-approve ) > "$LOG_DIR/tofu.log" 2>&1; then
            fail_step
            echo "    last 60 lines of $LOG_DIR/tofu.log:" >&2
            tail -n 60 "$LOG_DIR/tofu.log" >&2
            exit 1
        fi
        done_ok
    fi

    step 6 "Installing systemd-user unit that keeps kubectl port-forwards alive"
    run port-forward-install just port-forward-install || echo "    warning: no systemd-user available, skipping"

    step 7 "Waiting for Superset deployment rollout"
    run superset-rollout kubectl -n {{ns}} rollout status deploy/superset --timeout=5m

    step 8 "Waiting for Superset HTTP /health to respond"
    run wait-superset just wait-superset

    step 9 "Syncing EVERSE indicators and dimensions catalog into PostgreSQL"
    run trigger-sync just trigger-sync

    step 10 "Importing Superset dashboards, charts and datasets (Ansible)"
    run setup-dashboards just setup-dashboards

    echo
    echo "==> deploy complete. Visit the frontend (e.g. http://localhost:8080 or your prod URL)."

trigger-sync:
    #!/usr/bin/env bash
    set -uo pipefail
    job_name="sync-bootstrap-$(date +%s)"
    echo "    syncing EVERSE indicators and dimensions catalog from upstream"
    echo "    one-shot job: $job_name"
    if ! kubectl -n {{ns}} create job "$job_name" --from=cronjob/everse-sync >/dev/null 2>&1; then
        echo "    warning: could not create sync job -- catalog may stay empty" >&2
        exit 0
    fi
    if ! kubectl -n {{ns}} wait --for=condition=complete --timeout=5m "job/$job_name" >/dev/null 2>&1; then
        echo "    warning: sync did not finish in 5m; check 'kubectl -n {{ns}} logs job/$job_name'" >&2
        exit 0
    fi
    echo "    sync complete"

wait-superset:
    #!/usr/bin/env bash
    echo "waiting for superset to respond on localhost:8088 ..."
    for i in $(seq 1 90); do
        if curl -sf -o /dev/null http://localhost:8088/health 2>/dev/null; then
            echo "  superset is responding (after ${i} attempts)"
            exit 0
        fi
        sleep 2
    done
    echo "warning: superset did not respond within 3 min -- continuing anyway" >&2

destroy:
    #!/usr/bin/env bash
    set -euo pipefail

    TOTAL=3
    VERBOSE="${VERBOSE:-0}"
    LOG_DIR="$(mktemp -d /tmp/dashverse-destroy-XXXXXX)"
    trap 'rm -rf "$LOG_DIR"' EXIT
    STEP_START=0

    step() {
        local n=$1; local desc=$2
        echo
        echo "==> [$n/$TOTAL] $desc"
        STEP_START=$(date +%s)
    }
    if [ -t 1 ]; then C_OK=$'\033[32m'; C_RESET=$'\033[0m'; else C_OK=""; C_RESET=""; fi
    if [ -t 2 ]; then C_FAIL=$'\033[31m'; else C_FAIL=""; fi
    done_ok()    { echo "    ${C_OK}[ok]${C_RESET} ($(( $(date +%s) - STEP_START ))s)"; }
    fail_step()  { echo "    ${C_FAIL}[failed]${C_RESET} after $(( $(date +%s) - STEP_START ))s" >&2; }

    run() {
        local label=$1; shift
        local log="$LOG_DIR/${label}.log"
        if [ "$VERBOSE" = "1" ]; then
            if ! "$@"; then fail_step; return 1; fi
        else
            if ! "$@" >"$log" 2>&1; then
                fail_step
                echo "    last 60 lines of $log:" >&2
                tail -n 60 "$log" >&2
                return 1
            fi
        fi
        done_ok
    }

    step 1 "Verifying required tools are on PATH"
    run check-deps just check-deps

    step 2 "Verifying minikube cluster is reachable"
    run check-minikube just check-minikube

    step 3 "Destroying Terraform-managed resources"
    if [ "$VERBOSE" = "1" ]; then
        ( cd deployment/terraform && tofu destroy -var-file="environments/{{env}}.tfvars" -auto-approve ) || { fail_step; exit 1; }
        done_ok
    else
        if ! ( cd deployment/terraform && tofu destroy -no-color -var-file="environments/{{env}}.tfvars" -auto-approve ) > "$LOG_DIR/tofu.log" 2>&1; then
            fail_step
            echo "    last 60 lines of $LOG_DIR/tofu.log:" >&2
            tail -n 60 "$LOG_DIR/tofu.log" >&2
            exit 1
        fi
        done_ok
    fi

    echo
    echo "==> destroy complete."

destroy-all:
    #!/usr/bin/env bash
    set -euo pipefail

    TOTAL=4
    VERBOSE="${VERBOSE:-0}"
    LOG_DIR="$(mktemp -d /tmp/dashverse-destroy-all-XXXXXX)"
    trap 'rm -rf "$LOG_DIR"' EXIT
    STEP_START=0

    step() {
        local n=$1; local desc=$2
        echo
        echo "==> [$n/$TOTAL] $desc"
        STEP_START=$(date +%s)
    }
    done_ok()   { echo "    [ok] ($(( $(date +%s) - STEP_START ))s)"; }
    fail_step() { echo "    [failed] after $(( $(date +%s) - STEP_START ))s" >&2; }

    run() {
        local label=$1; shift
        local log="$LOG_DIR/${label}.log"
        if [ "$VERBOSE" = "1" ]; then
            if ! "$@"; then fail_step; return 1; fi
        else
            if ! "$@" >"$log" 2>&1; then
                fail_step
                echo "    last 60 lines of $log:" >&2
                tail -n 60 "$log" >&2
                return 1
            fi
        fi
        done_ok
    }

    step 1 "Verifying required tools are on PATH"
    run check-deps just check-deps

    step 2 "Verifying minikube cluster is reachable"
    run check-minikube just check-minikube

    step 3 "Destroying Terraform-managed resources"
    if [ "$VERBOSE" = "1" ]; then
        ( cd deployment/terraform && tofu destroy -var-file="environments/{{env}}.tfvars" -auto-approve ) || { fail_step; exit 1; }
        done_ok
    else
        if ! ( cd deployment/terraform && tofu destroy -no-color -var-file="environments/{{env}}.tfvars" -auto-approve ) > "$LOG_DIR/tofu.log" 2>&1; then
            fail_step
            echo "    last 60 lines of $LOG_DIR/tofu.log:" >&2
            tail -n 60 "$LOG_DIR/tofu.log" >&2
            exit 1
        fi
        done_ok
    fi

    step 4 "Deleting minikube cluster"
    run minikube-delete minikube delete --all

    echo
    echo "==> destroy-all complete."

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
                | sed -u "s/^/[$svc] /" &
            local pid=$!
            local fail=0
            while kill -0 "$pid" 2>/dev/null; do
                sleep 10
                if nc -z {{forward_address}} "$port" 2>/dev/null; then
                    fail=0
                else
                    fail=$((fail+1))
                    if [ "$fail" -ge 3 ]; then
                        echo "[$svc] half-dead on {{forward_address}}:$port -- reconnecting"
                        pkill -TERM -P "$pid" 2>/dev/null || true
                        kill -TERM "$pid" 2>/dev/null || true
                        break
                    fi
                fi
            done
            wait "$pid" 2>/dev/null || true
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
    systemctl --user enable dashverse-port-forward.service
    pkill -f 'kubectl.*port-forward' 2>/dev/null || true
    systemctl --user restart dashverse-port-forward.service
    echo "installed ${UNIT_PATH}"
    sleep 1
    state=$(systemctl --user is-active dashverse-port-forward.service 2>/dev/null || true)
    enabled=$(systemctl --user is-enabled dashverse-port-forward.service 2>/dev/null || true)
    echo "  dashverse-port-forward.service: ${state:-unknown} (enabled: ${enabled:-unknown})"

port-forward-status:
    #!/usr/bin/env bash
    state=$(systemctl --user is-active dashverse-port-forward.service 2>/dev/null || true)
    enabled=$(systemctl --user is-enabled dashverse-port-forward.service 2>/dev/null || true)
    echo "dashverse-port-forward.service: ${state:-unknown} (enabled: ${enabled:-unknown})"

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
    minikube image build -t dashverse/backend:latest backend/

build-frontend:
    minikube image build -t dashverse/frontend:latest frontend/

setup-dashboards: check-deps check-minikube
    kubectl -n {{ns}} rollout status deploy/postgresql --timeout=3m
    kubectl -n {{ns}} rollout status deploy/superset --timeout=5m
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
