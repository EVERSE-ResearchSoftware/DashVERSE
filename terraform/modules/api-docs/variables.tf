variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "name" {
  description = "Name identifier for the API docs service"
  type        = string
}

variable "labels" {
  description = "Common labels for resources"
  type        = map(string)
  default     = {}
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "image" {
  description = "Scalar API Reference Docker image"
  type        = string
  default     = "scalarapi/api-reference:latest"
}

variable "openapi_url" {
  description = "URL to the OpenAPI specification"
  type        = string
}

variable "theme" {
  description = "Scalar theme"
  type        = string
  default     = "purple"
}

variable "service_port" {
  description = "Port for the Kubernetes service"
  type        = number
  default     = 8080
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "64Mi"
}
