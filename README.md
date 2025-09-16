# DashVERSE

The dashboard prototype for the [EVERSE project](https://everse.software/).

> [!WARNING]
> 🚧 Work in Progress
>
> This project is currently under active development and may not yet be fully stable. Features, functionality, and documentation are subject to change as progress continues.
>
> We welcome feedback, contributions, and suggestions! If you encounter issues or have ideas for improvement, please feel free to open an issue or submit a pull request.

## Requirements

- Python (3.12)
- Poetry (1.8.5)
- Podman (5.4.1)
- minikube (v1.34.0)
- helm (v3.16.4)

<details>
<summary>
    Links for the requirements
</summary>

### Python

<https://www.python.org/downloads>

### Pyenv (optional)

Pyenv allows developers to install multiple versions of Python distribution and easy switching between the installed versions.

Website: <https://github.com/pyenv/pyenv?tab=readme-ov-file#installation>

### Poetry (optional)

Poetry is used for dependency management of the Python packages.

<https://python-poetry.org/docs/#installation>

### Podman

<https://podman.io/docs/installation>

### Docker

<https://docs.docker.com/engine/install>

### minikube

<https://minikube.sigs.k8s.io/docs/start>

### helm

<https://helm.sh/docs/intro/install>

</details>

## Deployment

If you would like to run the setup on a cloud (your own server)

1. Start a cluster using `minikube` and `podman`

Set the default driver (podman or docker)

````shell
 minikube config set driver podman
```shell

Start the cluster

```shell
minikube start --cpus='4' --memory='4g' --driver=podman
````

This will create a cluster using 4 cpus and 4GB of memory.

**The rest of the instructions need to be followed in `kubernetes` folder, so make sure you are in that folder before following the rest of the instructions:**

```shell
cd kubernetes
```

1. Generate Secrets for deployment

   ```shell
   bash generate-variables.sh
   ```

   This will generate or update the files below:

   - DBModel/db_config.json
   - deployments/XXXXXXXXXXXXX**DD_MM_YYYY**HH_MM/superset-deployment-secrets.yaml
   - deployments/XXXXXXXXXXXXX**DD_MM_YYYY**HH_MM/secrets.env
   - deployments/XXXXXXXXXXXXX**DD_MM_YYYY**HH_MM/generate_jwt.sh

   **Warning:** Do not share any of these generated files with anyone or push to a public repository!

   Now you can source the generated `secrets.env` file to set the environment variables which will be used for the deployment.

   ```shell
   source ./deployments/XXXXXXXXXXXXX**DD_MM_YYYY**HH_MM/secrets.env
   ```

1. Build database initialization container

   Build the docker image

   ```shell
   docker build --no-cache -t ghcr.io/everse-researchsoftware/postgresql-setup-script:latest -t everse-db-scripts:latest ./DBModel
   ```

   Load the docker image to the cluster

   ```shell
   minikube image load everse-db-scripts:latest
   ```

   Check if the image is loaded

   ```shell
   minikube image ls
   ```

**Warning:** Do not make this Docker image publicly available as it contains database password!

1. Create a namespace

   ```shell
   kubectl create namespace superset
   ```

1. Add Secrets to the cluster

   ```shell
   kubectl apply -f $DASHVERSE_SECRETS_FILE_NAME --namespace superset
   ```

1. Deploy db using `deploy-db.yaml`

   ```shell
   envsubst < deploy-db.yaml | kubectl apply --namespace superset -f -
   ```

   Check the logs of initialization job

   ```shell
   DB_JOB_POD_NAME=$(kubectl get pods --namespace superset | grep "postgresql-init-job" | cut -d" " -f1)
   kubectl logs --namespace superset $DB_JOB_POD_NAME -c init-python-container
   ```

1. Deploy API using `deploy-postgrest.yaml`

   ````shell
   envsubst < deploy-postgrest.yaml | kubectl apply --namespace superset -f -
   ```

    Check the logs

    ```shell
   POSTGREST_POD_NAME=$(kubectl get pods --namespace superset | grep "postgrest-" | cut -d" " -f1)
   kubectl logs --namespace superset $POSTGREST_POD_NAME --all-containers
   ````

Test using:

```shell
curl https://db.YOUR_DOMAIN/assessment
```

NODE_PORT=3000
curl $(minikube ip):$NODE_PORT

1. Deploy Apache Superset using `dashverse-values.yaml`

   ```shell
   helm repo add superset https://apache.github.io/superset
   ```

   ```shell
   envsubst < dashverse-values.yaml > dashverse-values-with-secrets.yaml

   helm upgrade --install superset superset/superset --values dashverse-values-with-secrets.yaml --namespace superset --create-namespace --debug --cleanup-on-fail

   rm -f dashverse-values-with-secrets.yaml
   ```

   Below are the commands you can use for debugging

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

1. **OPTIONAL** - Deploy pgadmin

   ```shell
   envsubst < deploy-pgadmin.yaml | kubectl apply --namespace superset -f -
   ```

   To add the postgresql database to pgadmin:

   ```shell
   Add a New server:
     General:
       Name --> postgres
     Connection:
       Host name --> superset-postgresql
       Port --> 5432
       Username --> $POSTGRES_USER in `XXXXXXXXXXXXX-superset-deployment-secrets` file
       Password --> see $POSTGRES_PASSWORD in `XXXXXXXXXXXXX-superset-deployment-secrets` file
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

List services

```shell
kubectl get --namespace superset services
```

Delete services

```shell
# database
kubectl delete service --namespace superset superset-postgresql

# postgrest API
kubectl delete service --namespace superset postgrest
kubectl delete service --namespace superset swagger

# pgadmin
kubectl delete service --namespace superset pgadmin

# superset
kubectl delete service --namespace superset superset
kubectl delete service --namespace superset superset-redis-headless
kubectl delete service --namespace superset superset-redis-master
```

List deployments

```shell
kubectl get deployments --namespace superset
```

Delete deployments

```shell
# database
kubectl delete deployment --namespace superset superset-postgresql
kubectl delete deployment --namespace superset postgrest

# pgadmin
kubectl delete deployment --namespace superset pgadmin

# superset
kubectl delete deployment --namespace superset superset
kubectl delete deployment --namespace superset superset-worker
```

List pvcs

```shell
kubectl get pvc --namespace superset

```

Delete pvcs

```shell
kubectl delete pvc --namespace superset superset-postgresql-data-pvc
kubectl delete pvc --namespace superset pgadmin-pvc
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
kubectl describe pod --namespace superset superset-postgresql-774c87bbfc-vn5mk # show the details of a specific pod

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

### Dashboard

```shell
minikube dashboard --url
```

```shell
kubectl proxy --address='0.0.0.0' --disable-filter=true
```

http://SERVER_IP:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/#/workloads?namespace=superset

### Delete the cluster and clean up

```shell
minikube stop
minikube delete --purge --all
```
