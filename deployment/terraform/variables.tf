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

variable "kube_config_path" {
  description = "Path to kubeconfig used by the kubernetes and helm providers"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kube context to target. Leave empty to use kubeconfig current-context."
  type        = string
  default     = ""
}

variable "common_labels" {
  type = map(string)
  default = {
    app = "dashverse"
  }
}

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

variable "postgrest_db_schema" {
  type    = string
  default = "api"
}

variable "postgrest_anon_role" {
  type    = string
  default = "web_anon"
}

variable "superset_admin_user" {
  type    = string
  default = "admin"
}

variable "superset_admin_email" {
  type    = string
  default = "admin@example.com"
}

variable "postgrest_external_url" {
  description = "Public URL of the PostgREST API the assessment client sees (e.g. https://api.dashverse.cloud)"
  type        = string
  default     = ""
}

variable "superset_external_url" {
  description = "Public URL of the Superset dashboard frame (e.g. https://dashverse.cloud)"
  type        = string
  default     = ""
}
