output "service_name" {
  description = "Name of the backend service"
  value       = kubernetes_service.backend.metadata[0].name
}

output "service_host" {
  description = "Auth-service service hostname (ClusterIP DNS)"
  value       = "${kubernetes_service.backend.metadata[0].name}.${var.namespace_name}.svc.cluster.local"
}

output "service_port" {
  description = "Auth-service service port"
  value       = kubernetes_service.backend.spec[0].port[0].port
}

output "service_url" {
  description = "Auth-service URL for internal access"
  value       = "http://${kubernetes_service.backend.metadata[0].name}.${var.namespace_name}.svc.cluster.local:${kubernetes_service.backend.spec[0].port[0].port}"
}

output "deployment_name" {
  description = "Name of the backend deployment"
  value       = kubernetes_deployment.backend.metadata[0].name
}
