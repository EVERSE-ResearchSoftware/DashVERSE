output "configmap_name" {
  value = kubernetes_config_map.schema.metadata[0].name
}
