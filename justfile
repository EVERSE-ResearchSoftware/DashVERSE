
env := "local"
ns := "dashverse"

default:
    @just --list

deploy: build-auth build-landing
    cd terraform && tofu init && tofu apply -var-file="environments/{{env}}.tfvars" -auto-approve

destroy:
    cd terraform && tofu destroy -var-file="environments/{{env}}.tfvars" -auto-approve

destroy-all: destroy
    minikube delete --all

status:
    kubectl get all -n {{ns}}

port-forward:
    @trap 'kill 0' INT TERM; \
    kubectl port-forward -n {{ns}} svc/postgresql 5432:5432 & \
    kubectl port-forward -n {{ns}} svc/postgrest 3000:3000 & \
    kubectl port-forward -n {{ns}} svc/superset 8088:8088 & \
    kubectl port-forward -n {{ns}} svc/auth-service 8000:8000 & \
    kubectl port-forward -n {{ns}} svc/landing 8080:8080 & \
    kubectl port-forward -n {{ns}} svc/postgrest-docs 3001:3001 & \
    kubectl port-forward -n {{ns}} svc/auth-docs 8001:8001 & \
    wait

logs:
    kubectl logs -n {{ns}} -l app=dashverse --all-containers -f

logs-postgres:
    kubectl logs -n {{ns}} -l component=postgresql -f

logs-postgrest:
    kubectl logs -n {{ns}} -l component=postgrest -f

logs-superset:
    kubectl logs -n {{ns}} -l app.kubernetes.io/name=superset -f

logs-auth:
    kubectl logs -n {{ns}} -l app=auth-service -f

logs-landing:
    kubectl logs -n {{ns}} -l app=landing -f

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

build-auth:
    if [ "{{env}}" = "local" ]; then \
        minikube image build -t dashverse/auth-service:latest auth-service/; \
    else \
        docker build -t dashverse/auth-service:latest auth-service/; \
    fi

build-landing:
    if [ "{{env}}" = "local" ]; then \
        minikube image build -t dashverse/landing:latest landing/; \
    else \
        docker build -t dashverse/landing:latest landing/; \
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
