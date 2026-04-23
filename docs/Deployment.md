# Deployment Checklist

Steps for deploying DashVERSE to a new environment.

## Prerequisites

- [ ] Kubernetes cluster running (minikube or managed)
- [ ] kubectl configured and connected
- [ ] OpenTofu or Terraform installed
- [ ] Helm installed
- [ ] Docker or Podman available for building images

## Deployment configurations

The deployment settings for both local (testing) and production environments can be found in `terraform/environments` folder.

## Initial Setup

1. Deploy all services

   ```shell
   make deploy ENV=local
   ```

1. Verify pods are running

   ```shell
   make status
   ```

1. On a `separate terminal` do port forwarding to be able to access the service

   ```shell
   make port-forward
   ```

1. Deploy the dashboards

   ```shell
   make setup-dashboards ENV=local
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
