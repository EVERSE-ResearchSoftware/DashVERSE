variable "namespace_name" {
  description = "Kubernetes namespace name"
  type        = string
  default     = "dashverse"
}

variable "environment" {
  type    = string
  default = "local"
}

variable "labels" {
  type = map(string)
  default = {
    app = "dashverse"
  }
}

variable "cpu_quota" {
  type    = string
  default = "4"
}

variable "memory_quota" {
  type    = string
  default = "8Gi"
}
