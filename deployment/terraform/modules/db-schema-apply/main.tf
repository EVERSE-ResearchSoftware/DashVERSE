
locals {
  apply_script = <<-EOT
    set -euo pipefail
    echo "waiting for postgresql to accept connections..."
    until PGPASSWORD="$$POSTGRES_PASSWORD" pg_isready -h postgresql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" >/dev/null 2>&1; do
      sleep 2
    done
    echo "postgresql is ready"

    echo "waiting for auth.projects (backend bootstrap)..."
    for i in $(seq 1 120); do
      reg="$$(PGPASSWORD="$$POSTGRES_PASSWORD" psql -h postgresql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -tAc "SELECT to_regclass('auth.projects')::text" 2>/dev/null || true)"
      if [ "$$reg" = "auth.projects" ]; then
        echo "  auth.projects is present"
        break
      fi
      echo "  not yet (attempt $$i/120) -- sleeping 5s"
      sleep 5
    done

    for f in ${join(" ", [for f in var.schema_files : "/sql/${f}"])}; do
      echo "applying $$f"
      PGPASSWORD="$$POSTGRES_PASSWORD" psql -v ON_ERROR_STOP=1 -h postgresql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -f "$$f"
    done

    echo "schema apply complete"
  EOT
}

resource "kubernetes_job_v1" "schema_apply" {
  metadata {
    name      = "db-schema-apply-${var.schema_hash}"
    namespace = var.namespace
    labels = merge(var.labels, {
      component = "db-schema-apply"
    })
  }

  spec {
    backoff_limit              = 5
    ttl_seconds_after_finished = 86400

    template {
      metadata {
        labels = merge(var.labels, {
          component = "db-schema-apply"
        })
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name              = "psql"
          image             = var.postgres_image
          image_pull_policy = "IfNotPresent"

          command = ["/bin/bash", "-c"]
          args    = [local.apply_script]

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = var.password_key
              }
            }
          }

          env {
            name  = "POSTGRES_USER"
            value = var.db_user
          }

          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }

          volume_mount {
            name       = "sql"
            mount_path = "/sql"
            read_only  = true
          }
        }

        volume {
          name = "sql"
          config_map {
            name = var.init_configmap
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "15m"
    update = "15m"
  }
}
