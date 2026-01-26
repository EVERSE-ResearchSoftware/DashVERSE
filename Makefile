.PHONY: deploy destroy status port-forward logs logs-auth logs-demo clean sync sync-apply jwt build-auth build-demo setup-dashboards seed-data

ENV ?= local
NS ?= dashverse
SYNC_DIR ?= /tmp/everse-sync

deploy: build-auth build-demo
	cd terraform && tofu init && tofu apply -var-file="environments/$(ENV).tfvars" -auto-approve

destroy:
	cd terraform && tofu destroy -var-file="environments/$(ENV).tfvars" -auto-approve

status:
	kubectl get all -n $(NS)

port-forward:
	./scripts/port-forward.sh

logs:
	kubectl logs -n $(NS) -l app=dashverse --all-containers -f

logs-postgres:
	kubectl logs -n $(NS) -l component=postgresql -f

logs-postgrest:
	kubectl logs -n $(NS) -l component=postgrest -f

logs-superset:
	kubectl logs -n $(NS) -l app.kubernetes.io/name=superset -f

logs-auth:
	kubectl logs -n $(NS) -l app=auth-service -f

clean:
	cd terraform && rm -rf .terraform .terraform.lock.hcl .tofu

sync:
	./scripts/sync-everse.sh $(SYNC_DIR)

sync-apply:
	./scripts/sync-everse.sh $(SYNC_DIR)
	./scripts/import-everse.sh $(SYNC_DIR) $(NS) --apply

sync-trigger:
	kubectl create job -n $(NS) --from=cronjob/everse-sync everse-sync-manual-$$(date +%s)

jwt:
	./scripts/generate-jwt.sh $(NS)

build-auth:
ifeq ($(ENV),local)
	minikube image build -t dashverse/auth-service:latest auth-service/
else
	docker build -t dashverse/auth-service:latest auth-service/
endif

build-demo:
ifeq ($(ENV),local)
	minikube image build -t dashverse/demo-portal:latest demo-portal/
else
	docker build -t dashverse/demo-portal:latest demo-portal/
endif

logs-demo:
	kubectl logs -n $(NS) -l app=demo-portal -f

setup-dashboards:
	cd ansible && \
		DATABASE_PASSWORD=$$(kubectl get secret $(NS)-secrets -n $(NS) -o jsonpath='{.data.postgres-password}' | base64 -d) \
		SUPERSET_PASSWORD=$$(kubectl get secret $(NS)-secrets -n $(NS) -o jsonpath='{.data.superset-admin-password}' | base64 -d) \
		ansible-playbook -i inventory/$(ENV).yml playbooks/configure_superset.yml

seed-data:
	./scripts/seed-data.sh $(NS) --apply
