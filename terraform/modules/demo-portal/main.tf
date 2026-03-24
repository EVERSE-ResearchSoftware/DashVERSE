resource "kubernetes_deployment" "demo_portal" {
  metadata {
    name      = "demo-portal"
    namespace = var.namespace_name
    labels    = var.common_labels
  }

  wait_for_rollout = false

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "demo-portal"
      }
    }

    template {
      metadata {
        labels = merge(
          var.common_labels,
          {
            app = "demo-portal"
          }
        )
      }

      spec {
        container {
          name              = "demo-portal"
          image             = var.demo_portal_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          env {
            name  = "SUPERSET_URL"
            value = var.superset_url
          }

          env {
            name  = "SUPERSET_EXTERNAL_URL"
            value = var.superset_external_url
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
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 2
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
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
}

resource "kubernetes_service" "demo_portal" {
  metadata {
    name      = "demo-portal"
    namespace = var.namespace_name
    labels    = var.common_labels
  }

  wait_for_load_balancer = false

  spec {
    type = "ClusterIP"

    selector = {
      app = "demo-portal"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
}
