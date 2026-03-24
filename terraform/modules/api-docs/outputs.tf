output "service_name" {
  description = "Name of the API docs service"
  value       = kubernetes_service.api_docs.metadata[0].name
}

output "url" {
  description = "Internal URL for API docs"
  value       = "http://${kubernetes_service.api_docs.metadata[0].name}.${var.namespace}.svc.cluster.local:${var.service_port}"
}

output "port" {
  description = "Service port"
  value       = var.service_port
}
