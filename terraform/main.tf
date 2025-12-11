# DashVERSE Infrastructure

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# namespace
module "namespace" {
  source = "./modules/namespace"

  namespace_name = var.namespace
  environment    = var.environment
  labels         = var.common_labels
}

# secrets
module "secrets" {
  source = "./modules/secrets"

  namespace = module.namespace.name
  labels    = var.common_labels
}

# db init scripts
module "db_init" {
  source = "./modules/db-init"

  namespace = module.namespace.name
  labels    = var.common_labels
}

# postgresql
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

# postgrest api
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

# superset
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

# sync cronjob for everse data
module "sync" {
  source = "./modules/sync"

  namespace    = module.namespace.name
  db_host      = module.postgresql.host
  db_name      = var.postgres_db
  db_user      = var.postgres_user
  secrets_name = module.secrets.secret_name
}

# auth service for jwt token generation
module "auth_service" {
  source = "./modules/auth-service"

  namespace_name = module.namespace.name
  common_labels  = var.common_labels
  secret_name    = module.secrets.secret_name
  postgres_host  = module.postgresql.host
  database_name  = var.postgres_db
  database_user  = var.postgres_user
  jwt_secret_key = "jwt-secret"

  module_depends_on = [module.postgresql]
}
