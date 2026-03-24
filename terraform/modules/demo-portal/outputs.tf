output "service_name" {
  description = "Name of the demo portal service"
  value       = kubernetes_service.demo_portal.metadata[0].name
}

output "url" {
  description = "Internal URL for demo portal"
  value       = "http://${kubernetes_service.demo_portal.metadata[0].name}.${var.namespace_name}.svc.cluster.local:8080"
}

output "port" {
  description = "Service port"
  value       = 8080
}
