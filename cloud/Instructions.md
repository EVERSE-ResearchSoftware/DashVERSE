# Cloud setup

If you would like to run the setup on a cloud (your own server)

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
