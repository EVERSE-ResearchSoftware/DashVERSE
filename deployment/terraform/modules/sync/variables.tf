variable "namespace" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type    = string
  default = "dashverse"
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "secrets_name" {
  type = string
}

variable "sync_schedule" {
  type        = string
  default     = "0 2 * * *"
  description = "Cron schedule for sync (default: daily at 2am)"
}

variable "indicators_ref" {
  type        = string
  default     = "main"
  description = <<-EOT
    Git ref (branch, tag, or commit SHA) of EVERSE-ResearchSoftware/indicators
    to fetch dimensions and indicators from. Default tracks main so unannounced
    upstream changes flow in immediately; set this to a specific commit SHA in
    production.tfvars so the prod catalog is reproducible and a breaking
    upstream change can't take the dashboard down. Example:
      indicators_ref = "9c7f4b3a..."
  EOT
}
