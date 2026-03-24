output "name" {
  description = "Namespace name"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "id" {
  value = kubernetes_namespace.this.id
}
