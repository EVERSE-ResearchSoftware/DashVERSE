output "release_name" {
  value = helm_release.superset.name
}

output "url" {
  value = "http://superset.${var.namespace}.svc.cluster.local:8088"
}

output "port" {
  value = 8088
}
