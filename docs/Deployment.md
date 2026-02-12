# Deployment Checklist

Steps for deploying DashVERSE to a new environment.

## Prerequisites

- [ ] Kubernetes cluster running (minikube or managed)
- [ ] kubectl configured and connected
- [ ] OpenTofu or Terraform installed
- [ ] Helm installed
- [ ] Docker or Podman available for building images

## Initial Setup

1. Build container images

   ```shell
   make build-auth
   make build-demo
   ```

2. Initialize Terraform

   ```shell
   cd terraform
   tofu init
   ```

3. Deploy all services

   ```shell
   make deploy
   ```

4. Verify pods are running

   ```shell
   make status
   ```

## Post-Deploy

- [ ] Run `make port-forward` and verify all services respond
- [ ] Import seed data: `make seed-data`
- [ ] Sync EVERSE indicators: `make sync-apply`
- [ ] Configure dashboards: `make setup-dashboards`
- [ ] Open Superset and verify dashboards load
- [ ] Test auth service login flow

## Production

For production deployments, use the production environment:

```shell
make deploy ENV=production
make setup-dashboards ENV=production
```

Verify external URLs in `terraform/environments/production.tfvars` before deploying.
