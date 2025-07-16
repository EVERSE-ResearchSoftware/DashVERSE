# Cloud setup

## Deployment

If you would like to run the setup on a cloud (your own server)

1. Start a cluster using `minikube` and `podman`

    ```shell
    minikube start --cpus='4' --memory='4g' --driver=podman
    ```

1. Build database initialization container

    ```shell
    cd DBModel

    docker build --no-cache -t ghcr.io/everse-researchsoftware/postgresql-setup-script:latest -t everse-db-scripts:latest .

    minikube image load everse-db-scripts:latest
    minikube image ls
    ```

1. Create a namespace

    ```shell
    cd cloud

    kubectl create namespace superset
    ```


1. Deploy db using `deploy-db.yaml`

    ```shell
    kubectl apply -f deploy-db.yaml --namespace superset
    kubectl get pods -A

    kubectl logs --namespace superset superset-postgresql-init-job-4mgrp -c init-sql-container
    kubectl logs --namespace superset superset-postgresql-init-job-4mgrp -c init-python-container
    ```

1. **OPTIONAL** - Deploy pgadmin

    ```shell
    kubectl apply -f deploy-pgadmin.yaml --namespace superset
    ```

    To add the postgresql database to pgadmin:
    ```
    Add a New server:
      General:
        Name --> postgres
      Connection:
        Host name --> superset-postgresql
        Port --> 5432
        Username --> superset
        Password --> see `superset-postgresql-secrets`
    ```

1. Deploy API using `deploy-postgrest.yaml`

    ```shell
    kubectl apply -f deploy-postgrest.yaml --namespace superset
    ```

    Test using:

    ```shell
    curl https://db.YOUR_DOMAIN/assessment
    ```

1. Deploy superset using `dashverse-values-with-ingress.yaml`

    ```shell
    helm upgrade --install superset superset/superset --values dashverse-values-with-ingress.yaml --namespace superset --create-namespace --debug --cleanup-on-fail
    ```

1. Get the application URL by running these commands:

    ```shell
    kubectl get --namespace superset services
    ```

    ```shell
      export SUPERSET_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services superset)
      export POSTGREST_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services postgrest)
      export SWAGGER_NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services swagger)

      export NODE_IP=$(kubectl get nodes --namespace superset -o jsonpath="{.items[0].status.addresses[0].address}")
      echo "superset: " http://$NODE_IP:$SUPERSET_NODE_PORT
      echo "postgrest: " http://$NODE_IP:$POSTGREST_NODE_PORT
      echo "swagger: " http://$NODE_IP:$SWAGGER_NODE_PORT
    ```

1. Set up the domain name for your server

1. Set DNS to point to your server ( you will need to setup a reverse proxy to be able to access the service)


## Clean up

### Delete services, deployments, volumes

```shell
kubectl delete service --namespace superset superset
kubectl delete service --namespace superset postgrest
kubectl delete service --namespace superset swagger
kubectl delete service --namespace superset pgadmin
kubectl delete service --namespace superset superset-postgresql
kubectl delete service --namespace superset superset-redis-headless
kubectl delete service --namespace superset superset-redis-master
kubectl get --namespace superset services

kubectl delete deployment --namespace superset pgadmin
kubectl delete deployment --namespace superset superset
kubectl delete deployment --namespace superset postgrest
kubectl delete deployment --namespace superset superset-postgresql
kubectl delete deployment --namespace superset superset-worker
kubectl get deployments --namespace superset

kubectl delete pvc --namespace superset pgadmin-pvc
kubectl delete pvc --namespace superset superset-postgresql-data-pvc
kubectl get pvc --namespace superset
```

### Get info

```shell

minikube --namespace superset service list
#minikube --namespace superset service --all
minikube --namespace superset service superset-postgresql --url
minikube --namespace superset service superset --url
minikube --namespace superset service postgrest --url
minikube --namespace superset service swagger --url
minikube --namespace superset service pgadmin --url

kubectl get --namespace superset services
kubectl get --namespace superset deployments
kubectl get --namespace superset deployments.apps

kubectl get pods --namespace superset
```

### Delete the cluster

```shell
minikube stop
minikube delete --purge --all
```
