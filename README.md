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
- Docker (27.4.1)
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

### Docker

<https://docs.docker.com/engine/install>

### minikube

<https://minikube.sigs.k8s.io/docs/start>

### helm

<https://helm.sh/docs/intro/install>

</details>

## Step-1 Setting up a Kubernetes Cluster

This step will set up a Kubernetes cluster using minikube.

### Check versions

```shell
$ minikube version
minikube version: v1.34.0
commit: 210b148df93a80eb872ecbeb7e35281b3c582c61
```

```shell
$ kubectl version --client
Client Version: v1.31.1
Kustomize Version: v5.4.2
```

### Start the cluster

 The kubernetes cluster will be deployed using Docker driver. For the alternative drivers have a look at [this link](https://minikube.sigs.k8s.io/docs/drivers/).

```shell
minikube start --cpus='4' --memory='8g' --driver=docker  # or podman
```

List the pods:

```shell
minikube kubectl -- get pods -A
```

## Step-2 Deploy a Superset instance

- Add the Superset helm repository

    ```shell
    helm repo add superset https://apache.github.io/superset
    ```

- View charts in repo

    ```shell
    helm search repo superset
    ```

- Install and run

    ```shell
    helm upgrade --install \
        --debug --cleanup-on-fail \
        --values dashverse-values.yaml superset superset/superset
    ```

- Create a tunnel between the superset pod and your localhost

    For the frontend:

    ```shell
    kubectl port-forward service/superset 8088:8088 --namespace default
    ```

## Step-3 Set up the database

To be able to access the database service, create a tunnel between the database pod and your localhost:

```shell
kubectl port-forward service/superset-postgresql 5432:5432 --namespace default
```

You should now be able to access the database service at `0.0.0.0:5432`

### The database schema

<!-- cd postgres
cat ./schema/schema_*.sql > db_schema.sql

python scripts/execute_sql.py --db-file db_config_superset.json  --sql-file ./schema/db_schema.sql -->

```shell
eval (poetry env activate)
poetry install

cd PydanticModel
python main.py --config db_config.json
```

### Add sample data to the database

```shell
cd postgres/docker
docker compose -f docker-compose.yml up pgadmin
```

For pgadmin visit http://localhost:5050/browser/

#### Adding data using pgadmin

```text
click
  --> Servers
  --> "Superset Postgres Server"
  --> Databases
  -- Schemas
  --> everse
  --> Tables
Right click a table and click "View/Edit Data" --> "All Rows"
Add a row in the bottom part of the screen
```

#### Adding data using sql

```shell
cd PydanticModel
python populate_data.py --config db_config.json --num_indicator 10 --num_dimension 10 --num_software 10 --num_assessment 10 --num_content_relation 10
```

To remove all the database entries

```shell
python populate_data.py --config db_config.json --clear
```

## Configuring superset datasets, charts, dashboard

```shell
cd cli
python example_usage.py --config config.json
```

### Superset Frontend

http://localhost:8088

## Testing

### API endpoints

Thedocumentation for the API is at <http://localhost:8088/swagger/v1>

## Clean up

The command below will remove the kubernetes cluster and purge all the data.

```shell
minikube stop
minikube delete --purge --all
```
