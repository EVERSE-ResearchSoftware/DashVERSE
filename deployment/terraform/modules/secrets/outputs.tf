output "secret_name" {
  value = kubernetes_secret.main.metadata[0].name
}

output "postgres_password_key" {
  value = "postgres-password"
}

output "postgres_password" {
  value     = kubernetes_secret.main.data["postgres-password"]
  sensitive = true
}

output "jwt_secret_key" {
  value = "jwt-secret"
}

output "superset_admin_password_key" {
  value = "superset-admin-password"
}

output "superset_admin_password" {
  value     = kubernetes_secret.main.data["superset-admin-password"]
  sensitive = true
}
