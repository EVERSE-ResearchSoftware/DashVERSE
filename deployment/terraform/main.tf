
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "namespace" {
  source = "./modules/namespace"

  namespace_name = var.namespace
  environment    = var.environment
  labels         = var.common_labels
}

module "secrets" {
  source = "./modules/secrets"

  namespace = module.namespace.name
  labels    = var.common_labels
}

module "db_init" {
  source = "./modules/db-init"

  namespace = module.namespace.name
  labels    = var.common_labels
}

module "postgresql" {
  source = "./modules/postgresql"

  namespace      = module.namespace.name
  labels         = var.common_labels
  secret_name    = module.secrets.secret_name
  image          = var.postgres_image
  db_name        = var.postgres_db
  db_user        = var.postgres_user
  init_configmap = module.db_init.configmap_name
}

module "postgrest" {
  source = "./modules/postgrest"

  namespace      = module.namespace.name
  labels         = var.common_labels
  secret_name    = module.secrets.secret_name
  db_host        = module.postgresql.host
  db_name        = var.postgres_db
  db_user        = var.postgres_user
  jwt_secret_key = "jwt-secret"
}

module "superset" {
  source = "./modules/superset"

  namespace      = module.namespace.name
  secret_name    = module.secrets.secret_name
  db_host        = module.postgresql.service_name
  db_name        = var.postgres_db
  db_user        = var.postgres_user
  db_pass        = module.secrets.postgres_password
  admin_password = module.secrets.superset_admin_password
}

module "sync" {
  source = "./modules/sync"

  namespace    = module.namespace.name
  db_host      = module.postgresql.host
  db_name      = var.postgres_db
  db_user      = var.postgres_user
  secrets_name = module.secrets.secret_name
}

module "backend" {
  source = "./modules/backend"

  namespace_name = module.namespace.name
  common_labels  = var.common_labels
  secret_name    = module.secrets.secret_name
  postgres_host  = module.postgresql.host
  database_name  = var.postgres_db
  database_user  = var.postgres_user
  jwt_secret_key = "jwt-secret"

  module_depends_on = [module.postgresql]
}

module "frontend" {
  source = "./modules/frontend"

  namespace_name = module.namespace.name
  common_labels  = var.common_labels
  superset_url   = "http://${module.superset.service_name}:${module.superset.port}"
  secret_name    = module.secrets.secret_name
  jwt_secret_key = "jwt-secret"
  postgrest_url  = "http://postgrest:3000"
}

module "postgrest_docs" {
  source = "./modules/api-docs"

  namespace    = module.namespace.name
  name         = "postgrest-docs"
  labels       = var.common_labels
  openapi_url  = "http://postgrest:3000/"
  theme        = "purple"
  service_port = 3001
}

module "backend_docs" {
  source = "./modules/api-docs"

  namespace    = module.namespace.name
  name         = "backend-docs"
  labels       = var.common_labels
  openapi_url  = "http://backend:8000/openapi.json"
  theme        = "blue"
  service_port = 8001
}
