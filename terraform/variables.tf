variable "namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
  default     = "dashverse"
}

variable "environment" {
  description = "Deployment environment (local, production)"
  type        = string
  default     = "local"
}

variable "common_labels" {
  type = map(string)
  default = {
    app = "dashverse"
  }
}

# PostgreSQL configuration
variable "postgres_image" {
  type    = string
  default = "postgres:17-alpine"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dashverse"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "dashverse"
}

variable "postgres_storage_size" {
  type    = string
  default = "10Gi"
}

# PostgREST config
variable "postgrest_db_schema" {
  type    = string
  default = "api"
}

variable "postgrest_anon_role" {
  type    = string
  default = "web_anon"
}

# Superset config
variable "superset_admin_user" {
  type    = string
  default = "admin"
}

variable "superset_admin_email" {
  type    = string
  default = "admin@example.com"
}
