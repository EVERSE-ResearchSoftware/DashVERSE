resource "helm_release" "superset" {
  name       = "superset"
  repository = "https://apache.github.io/superset"
  chart      = "superset"
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      db_host             = var.db_host
      db_port             = var.db_port
      db_user             = var.db_user
      db_pass             = var.db_pass
      db_name             = var.db_name
      secret_name         = var.secret_name
      password_key        = var.password_key
      superset_secret_key = var.superset_secret_key
      admin_password      = var.admin_password
    })
  ]

  timeout = 600
  wait    = false
}
