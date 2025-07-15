# Cloud setup

If you would like to run the setup on a cloud (your own server)

1. Deploy superset using `dashverse-values-with-ingress.yaml`

1. Change the database password in `deploy-postgrest.yaml`:
"postgres://USERNAME:PASSWORD@superset-postgresql:5432/superset"
<!-- TODO: update the password during the deployment and automatically replace with generated secrets -->

1. Deploy postgrest:

```shell
kubectl apply -f deploy-postgrest.yaml --namespace superset
kubectl get --namespace superset services
```

1. Get the application URL by running these commands:

```shell
  export SUPERSET_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services superset)
  export POSTGREST_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services postgrest)
  export SWAGGER_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[1].nodePort}" services postgrest)
  export NODE_IP=$(kubectl get nodes --namespace superset -o jsonpath="{.items[0].status.addresses[0].address}")
  echo "superset: " http://$NODE_IP:$SUPERSET_NODE_PORT
  echo "postgrest: " http://$NODE_IP:$POSTGREST_NODE_PORT
  echo "swagger: " http://$NODE_IP:$SWAGGER_NODE_PORT
```

1. Set up the domain

1. Set DNS to point to your server ( you will need to setup a reverse proxy to be able to access the service)
