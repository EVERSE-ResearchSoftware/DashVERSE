output "service_name" {
  value = kubernetes_service.postgrest.metadata[0].name
}

output "url" {
  value = "http://${kubernetes_service.postgrest.metadata[0].name}.${var.namespace}.svc.cluster.local:3000"
}

output "port" {
  value = 3000
}
