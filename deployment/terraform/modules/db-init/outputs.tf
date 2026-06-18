output "configmap_name" {
  value = kubernetes_config_map.schema.metadata[0].name
}

output "schema_hash" {
  value = substr(
    sha256(
      join("\n", [for k in sort(keys(local.schema_files)) : local.schema_files[k]])
    ),
    0,
    10,
  )
}
