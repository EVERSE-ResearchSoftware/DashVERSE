resource "kubernetes_deployment" "postgrest" {
  metadata {
    name      = "postgrest"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app       = "dashverse"
        component = "postgrest"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          component = "postgrest"
        })
      }

      spec {
        container {
          name  = "postgrest"
          image = var.image

          port {
            container_port = 3000
          }

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
            name  = "PGRST_DB_URI"
            value = "postgresql://${var.db_user}:$(POSTGRES_PASSWORD)@${var.db_host}:${var.db_port}/${var.db_name}"
          }

          env {
            name  = "PGRST_DB_SCHEMA"
            value = var.db_schema
          }

          env {
            name  = "PGRST_DB_ANON_ROLE"
            value = var.anon_role
          }

          env {
            name  = "PGRST_SERVER_PORT"
            value = "3000"
          }

          # jwt config
          dynamic "env" {
            for_each = var.jwt_secret_key != "" ? [1] : []
            content {
              name = "PGRST_JWT_SECRET"
              value_from {
                secret_key_ref {
                  name = var.secret_name
                  key  = var.jwt_secret_key
                }
              }
            }
          }

          env {
            name  = "PGRST_JWT_ROLE_CLAIM_KEY"
            value = ".role"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgrest" {
  metadata {
    name      = "postgrest"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    selector = {
      app       = "dashverse"
      component = "postgrest"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}
