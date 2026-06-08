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
