variable "namespace_name" {
  description = "Kubernetes namespace"
  type        = string
}

variable "demo_portal_image" {
  description = "Docker image for demo portal"
  type        = string
  default     = "dashverse/demo-portal:latest"
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
