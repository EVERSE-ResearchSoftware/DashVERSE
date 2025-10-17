# Kubernetes notes

- Verify the running pods

    ```shell
    kubectl get pods
    ```

- To list deployment events run

    ```shell
    kubectl get events
    ```

- Regenerate deployment secrets without hardcoding domains by exporting `EVERSE_DOMAIN_NAME` before running `generate-variables.sh`.

- To check the logs of a pod run

    ```shell
    kubectl logs superset-postgresql-0
    ```

- The generated secrets directory now contains dedicated credentials for Superset, PostgREST, Redis, and the PostgreSQL superuser (`POSTGREST_AUTH_PASSWORD`, `POSTGREST_JWT_SECRET`, etc.). Keep the folder under `kubernetes/deployments/` out of version control and `source` the `secrets.env` file before applying manifests with `envsubst`.
