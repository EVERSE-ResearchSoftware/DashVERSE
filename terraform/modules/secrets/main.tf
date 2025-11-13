# generate passwords if not provided
resource "random_password" "postgres" {
  count   = var.postgres_password == "" ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "superset_admin" {
  count   = var.superset_admin_password == "" ? 1 : 0
  length  = 24
  special = false
}

resource "random_id" "jwt" {
  count       = var.jwt_secret == "" ? 1 : 0
  byte_length = 32
}

resource "random_id" "superset" {
  count       = var.superset_secret_key == "" ? 1 : 0
  byte_length = 32
}

resource "kubernetes_secret" "main" {
  metadata {
    name      = "${var.namespace}-secrets"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    postgres-password       = var.postgres_password != "" ? var.postgres_password : random_password.postgres[0].result
    jwt-secret              = var.jwt_secret != "" ? var.jwt_secret : random_id.jwt[0].hex
    superset-secret-key     = var.superset_secret_key != "" ? var.superset_secret_key : random_id.superset[0].hex
    superset-admin-password = var.superset_admin_password != "" ? var.superset_admin_password : random_password.superset_admin[0].result
  }

  type = "Opaque"
}
