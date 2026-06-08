output "service_name" {
  description = "Name of the frontend service"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "url" {
  description = "Internal URL for frontend site"
  value       = "http://${kubernetes_service.frontend.metadata[0].name}.${var.namespace_name}.svc.cluster.local:8080"
}

output "port" {
  description = "Service port"
  value       = 8080
}
