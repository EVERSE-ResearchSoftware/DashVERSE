resource "kubernetes_deployment" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = var.namespace_name
    labels    = var.common_labels
  }

  wait_for_rollout = false

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "auth-service"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            app = "auth-service"
          }
        )
      }

      spec {
        init_container {
          name              = "wait-for-schema"
          image             = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"

          command = [
            "/bin/sh",
            "-c",
            <<-EOF
            echo "Waiting for auth schema to be created..."
            until PGPASSWORD=$POSTGRES_PASSWORD psql -h ${var.postgres_host} -U ${var.database_user} -d ${var.database_name} -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'auth';" | grep -q auth; do
              echo "Schema not found, waiting 5 seconds..."
              sleep 5
            done
            echo "Schema found, ready to start auth-service"
            EOF
          ]

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = var.postgres_password_key
              }
            }
          }

          security_context {
            run_as_non_root            = false
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        container {
          name              = "auth-service"
          image             = var.auth_service_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8000
            protocol       = "TCP"
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = var.postgres_password_key
              }
            }
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql://${var.database_user}:$(POSTGRES_PASSWORD)@${var.postgres_host}:${var.postgres_port}/${var.database_name}"
          }

          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = var.secret_name
                key  = var.jwt_secret_key
              }
            }
          }

          env {
            name  = "JWT_ALGORITHM"
            value = "HS256"
          }

          env {
            name  = "JWT_EXPIRATION_DAYS"
            value = tostring(var.jwt_expiration_days)
          }

          env {
            name  = "PASSWORD_MIN_LENGTH"
            value = tostring(var.password_min_length)
          }

          env {
            name  = "MAX_LOGIN_ATTEMPTS"
            value = tostring(var.max_login_attempts)
          }

          env {
            name  = "LOCKOUT_DURATION_MINUTES"
            value = tostring(var.lockout_duration_minutes)
          }

          env {
            name  = "LOG_LEVEL"
            value = var.log_level
          }

          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 2
          }

          security_context {
            run_as_non_root             = true
            run_as_user                 = 1000
            allow_privilege_escalation  = false
            read_only_root_filesystem   = false
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        security_context {
          fs_group = 1000
        }
      }
    }
  }

  depends_on = [var.module_depends_on]
}

resource "kubernetes_service" "auth_service" {
  metadata {
    name      = "auth-service"
    namespace = var.namespace_name
    labels    = var.common_labels
  }

  wait_for_load_balancer = false

  spec {
    type = "ClusterIP"

    selector = {
      app = "auth-service"
    }

    port {
      name        = "http"
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }
  }
}
