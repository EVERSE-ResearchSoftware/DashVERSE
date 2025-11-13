variable "namespace" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "postgres_password" {
  description = "PostgreSQL password (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jwt_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "superset_secret_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "superset_admin_password" {
  description = "Superset admin password (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
}
