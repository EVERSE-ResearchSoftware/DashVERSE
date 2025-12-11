output "namespace" {
  value = module.namespace.name
}

output "postgresql_host" {
  value = module.postgresql.host
}

output "postgresql_port" {
  value = module.postgresql.port
}

output "postgrest_url" {
  value = module.postgrest.url
}

output "postgrest_port" {
  value = module.postgrest.port
}

output "superset_url" {
  value = module.superset.url
}

output "superset_port" {
  value = module.superset.port
}

output "auth_service_url" {
  value = module.auth_service.service_url
}

output "auth_service_port" {
  value = module.auth_service.service_port
}
