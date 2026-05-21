
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
    POD=$(kubectl get pod -n {{ns}} -l app.kubernetes.io/name=superset -o jsonpath='{.items[0].metadata.name}') && \
    echo "Exporting from pod $POD" && \
    rm -rf $OUT_DIR && \
    mkdir -p $OUT_DIR && \
    kubectl exec -n {{ns}} $POD -- superset export-dashboards -f /tmp/dashverse-assets.zip && \
    kubectl cp {{ns}}/$POD:/tmp/dashverse-assets.zip /tmp/dashverse-assets.zip && \
    unzip -q /tmp/dashverse-assets.zip -d $OUT_DIR && \
    rm /tmp/dashverse-assets.zip && \
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
