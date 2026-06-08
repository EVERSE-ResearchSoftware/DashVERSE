resource "kubernetes_deployment" "api_docs" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = var.labels
  }

  wait_for_rollout = false

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          app = var.name
        })
      }

      spec {
        init_container {
          name  = "fetch-openapi"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            echo "Waiting for API to be ready..."
            until wget -q --spider ${var.openapi_url}; do
              echo "API not ready, waiting..."
              sleep 5
            done
            echo "Fetching OpenAPI spec from ${var.openapi_url}"
            wget -O /docs/openapi.json ${var.openapi_url}
            echo "OpenAPI spec saved to /docs/openapi.json"
            EOT
          ]

          volume_mount {
            name       = "openapi-docs"
            mount_path = "/docs"
          }
        }

        container {
          name              = var.name
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = var.container_port
            protocol       = "TCP"
          }

          env {
            name  = "API_REFERENCE_CONFIG"
            value = jsonencode({
              theme = var.theme
            })
          }

          volume_mount {
            name       = "openapi-docs"
            mount_path = "/docs"
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
              port = var.container_port
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 2
          }
        }

        volume {
          name = "openapi-docs"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "api_docs" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = var.labels
  }

  wait_for_load_balancer = false

  spec {
    type = "ClusterIP"

    selector = {
      app = var.name
    }

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }
  }
}
