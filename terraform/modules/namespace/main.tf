resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace_name

    labels = merge(var.labels, {
      environment = var.environment
    })

    annotations = {
      "dashverse.io/managed-by" = "terraform"
      "dashverse.io/env"        = var.environment
    }
  }
}

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "${var.namespace_name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"           = var.cpu_quota
      "requests.memory"        = var.memory_quota
      "persistentvolumeclaims" = "10"
      "pods"                   = "50"
    }
  }
}

# default limits for containers
resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${var.namespace_name}-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
}
