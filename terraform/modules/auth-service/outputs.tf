output "service_name" {
  description = "Name of the auth-service service"
  value       = kubernetes_service.auth_service.metadata[0].name
}

output "service_host" {
  description = "Auth-service service hostname (ClusterIP DNS)"
  value       = "${kubernetes_service.auth_service.metadata[0].name}.${var.namespace_name}.svc.cluster.local"
}

output "service_port" {
  description = "Auth-service service port"
  value       = kubernetes_service.auth_service.spec[0].port[0].port
}

output "service_url" {
  description = "Auth-service URL for internal access"
  value       = "http://${kubernetes_service.auth_service.metadata[0].name}.${var.namespace_name}.svc.cluster.local:${kubernetes_service.auth_service.spec[0].port[0].port}"
}

output "deployment_name" {
  description = "Name of the auth-service deployment"
  value       = kubernetes_deployment.auth_service.metadata[0].name
}
