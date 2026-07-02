environment  = "production"
namespace    = "dashverse"
kube_context = "minikube"

postgres_image        = "postgres:17-alpine"
postgres_db           = "dashverse"
postgres_user         = "dashverse"
postgres_storage_size = "50Gi"

postgrest_external_url = "https://api.dashverse.cloud"
superset_external_url  = "https://analytics.dashverse.cloud"
api_docs_external_url  = "https://apidocs.dashverse.cloud"

indicators_ref = "main"
