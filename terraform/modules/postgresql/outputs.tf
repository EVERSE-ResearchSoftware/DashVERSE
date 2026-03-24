output "service_name" {
  value = kubernetes_service.postgres.metadata[0].name
}

output "host" {
  value = "${kubernetes_service.postgres.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "port" {
  value = 5432
}
