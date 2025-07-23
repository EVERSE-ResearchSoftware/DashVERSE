# Cloud setup

## Deployment

If you would like to run the setup on a cloud (your own server)

1. Start a cluster using `minikube` and `podman`

    ```shell
    minikube start --cpus='4' --memory='4g' --driver=podman
    ```

1. Generate Secrets for deployment

    ```shell
    cd cloud

    bash generate-variables.sh
    ```

    This will generate or update the files below:

    - DBModel/db_config.json
    - XXXXXXXXXXXXX-superset-deployment-secrets.yaml
    - XXXXXXXXXXXXX-secrets.env

    **Warning:** Do not share or push any of these generated files with anyone!

    ```shell
    source ./XXXXXX-secrets.env
    ```

1. Build database initialization container

    ```shell
    cd DBModel

    # docker image prune
    # docker rmi -f $(docker images 'everse-db-scripts' -a -q) # remove existing image

    docker build --no-cache -t ghcr.io/everse-researchsoftware/postgresql-setup-script:latest -t everse-db-scripts:latest .

    minikube image load everse-db-scripts:latest
    minikube image ls
    ```

    **Warning:** Do not make this Docker image publicly available as it contains database password!

1. Create a namespace

    ```shell
    cd cloud

    kubectl create namespace superset
    ```

1. Add Secrets to the cluster

    ```shell
    cd cloud

    kubectl apply -f RCgQgzJN28clh-superset-deployment-secrets.yaml --namespace superset
    ```

1. Deploy db using `deploy-db.yaml`

    ```shell
    cd cloud

    #kubectl apply -f deploy-db.yaml --namespace superset

    envsubst < deploy-db.yaml | kubectl apply --namespace superset -f -

    kubectl get pods -A

    kubectl describe pod --namespace superset superset-postgresql-774c87bbfc-vn5mk

    JOB_POD_NAME=$(kubectl get pods --namespace superset | grep "postgresql-init-job" | cut -d" " -f1)
    kubectl logs --namespace superset $JOB_POD_NAME -c init-python-container
    # kubectl logs --namespace superset $JOB_POD_NAME -c init-sql-container
    ```

1. **OPTIONAL** - Deploy pgadmin

    ```shell
    kubectl apply -f deploy-pgadmin.yaml --namespace superset
    ```

    To add the postgresql database to pgadmin:

    ```shell
    Add a New server:
      General:
        Name --> postgres
      Connection:
        Host name --> superset-postgresql
        Port --> 5432
        Username --> superset
        Password --> see `XXXXXXXXXXXXX-superset-deployment-secrets` file
    ```

1. Deploy API using `deploy-postgrest.yaml`

    ```shell
    cd cloud
    source ./XXXXXX-secrets.env

    envsubst < deploy-postgrest.yaml | kubectl apply --namespace superset -f -

    POSTGREST_POD_NAME=$(kubectl get pods --namespace superset | grep "postgrest-" | cut -d" " -f1)
    kubectl logs --namespace superset $POSTGREST_POD_NAME --all-containers
    ```

    Test using:

    ```shell
    curl https://db.YOUR_DOMAIN/assessment
    ```

1. Deploy superset using `dashverse-values-with-ingress.yaml`

    ```shell
    envsubst < dashverse-values-with-ingress.yaml > dashverse-superset-values-with-secrets.yaml

    helm upgrade --install superset superset/superset --values dashverse-superset-values-with-secrets.yaml --namespace superset --create-namespace --debug --cleanup-on-fail

    rm -f dashverse-superset-values-with-secrets.yaml
    ```

    ```shell
    kubectl describe job --namespace superset superset-init-db
    ```

    ```shell
    kubectl logs --namespace superset  superset-init-db-7nccv
    ```

    ```shell
    kubectl get pods --namespace superset  -l job-name=superset-init-db
    ```

    ```shell
    kubectl describe pod --namespace superset superset-init-db-hczfw
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

kubectl get pods --all-namespaces
kubectl get pods --namespace superset

kubectl describe pods --namespace superset

kubectl cluster-info

kubectl get pods -l app=superset-postgresql --namespace superset
kubectl get jobs -l job-name=superset-postgresql-init-job --namespace superset
kubectl logs -f <superset-postgresql-init-job-pod-name> --namespace superset
```

### Connect to Postgresql server

```shell
kubectl get pods --namespace superset
kubectl exec -ti superset-postgresql-6c8dd65c-5k4d4 --namespace superset -- bash
psql -U postgres -d postgres -h localhost
```

**Note**: use your own username and password for the `psql` command

### Delete the cluster

```shell
minikube stop
minikube delete --purge --all
```
