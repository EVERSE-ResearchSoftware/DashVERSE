variable "namespace_name" {
  description = "Kubernetes namespace"
  type        = string
}

variable "frontend_image" {
  description = "Docker image for frontend site"
  type        = string
  default     = "dashverse/frontend:latest"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "superset_url" {
  description = "URL for Superset service (internal)"
  type        = string
  default     = "http://superset:8088"
}

variable "superset_external_url" {
  description = "External URL for Superset (for iframe embedding)"
  type        = string
  default     = ""
}

variable "log_level" {
  description = "Log level"
  type        = string
  default     = "INFO"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "250m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "common_labels" {
  description = "Common labels for resources"
  type        = map(string)
  default     = {}
}

variable "secret_name" {
  description = "Name of the k8s secret holding the shared JWT secret"
  type        = string
}

variable "jwt_secret_key" {
  description = "Key within the secret pointing at the JWT signing secret"
  type        = string
  default     = "jwt-secret"
}

variable "jwt_algorithm" {
  description = "JWT signing algorithm (must match backend)"
  type        = string
  default     = "HS256"
}

variable "postgrest_url" {
  description = "Internal URL of the PostgREST service"
  type        = string
  default     = "http://postgrest:3000"
}

variable "postgrest_external_url" {
  description = "External URL for PostgREST (what the assessment-submitting client sees, e.g. https://api.dashverse.cloud)"
  type        = string
  default     = ""
}

variable "api_docs_external_url" {
  description = "External URL for the user-visible API docs (e.g. https://apidocs.dashverse.cloud). Surfaced as the {{ api_docs_url }} template variable."
  type        = string
  default     = ""
}

variable "backend_url" {
  description = "Internal cluster URL for backend (used server-side for /api/auth/login proxying)"
  type        = string
  default     = "http://backend:8000"
}
