output "job_name" {
  value = kubernetes_job_v1.schema_apply.metadata[0].name
}
