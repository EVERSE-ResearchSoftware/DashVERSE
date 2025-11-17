# configmap for db initialization scripts
# loads SQL from database/sql/schema/ files

locals {
  sql_path = "${path.module}/../../../database/sql/schema"
}

resource "kubernetes_config_map" "schema" {
  metadata {
    name      = "db-init-schema"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    "01-schema.sql"      = file("${local.sql_path}/001_create_schema.sql")
    "02-tables.sql"      = file("${local.sql_path}/002_create_tables.sql")
    "03-indexes.sql"     = file("${local.sql_path}/003_create_indexes.sql")
    "04-triggers.sql"    = file("${local.sql_path}/004_create_triggers.sql")
    "05-rls.sql"         = file("${local.sql_path}/005_setup_rls.sql")
    "06-views.sql"       = file("${local.sql_path}/006_create_views.sql")
    "07-permissions.sql" = file("${local.sql_path}/007_grant_permissions.sql")
  }
}
