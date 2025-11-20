.PHONY: deploy destroy status port-forward logs clean sync-trigger

ENV ?= local
NS ?= dashverse

deploy:
	cd terraform && tofu init && tofu apply -var-file="environments/$(ENV).tfvars" -auto-approve

destroy:
	cd terraform && tofu destroy -var-file="environments/$(ENV).tfvars" -auto-approve

status:
	kubectl get all -n $(NS)

port-forward:
	@echo "Starting port forwarding..."
	kubectl port-forward -n $(NS) svc/postgrest 3000:3000 &
	kubectl port-forward -n $(NS) svc/postgresql 5432:5432 &
	kubectl port-forward -n $(NS) svc/superset 8088:8088 &
	@echo "PostgREST: http://localhost:3000"
	@echo "Superset:  http://localhost:8088"
	@echo "Postgres:  localhost:5432"

logs:
	kubectl logs -n $(NS) -l app=dashverse --all-containers -f

logs-postgres:
	kubectl logs -n $(NS) -l component=postgresql -f

logs-postgrest:
	kubectl logs -n $(NS) -l component=postgrest -f

logs-superset:
	kubectl logs -n $(NS) -l app.kubernetes.io/name=superset -f

clean:
	cd terraform && rm -rf .terraform .terraform.lock.hcl .tofu

sync-trigger:
	kubectl create job -n $(NS) --from=cronjob/everse-sync everse-sync-manual-$$(date +%s)
