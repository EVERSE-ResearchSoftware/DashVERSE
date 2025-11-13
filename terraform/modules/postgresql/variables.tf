variable "namespace" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = { app = "dashverse" }
}

variable "image" {
  type    = string
  default = "postgres:17-alpine"
}

variable "db_name" {
  type    = string
  default = "dashverse"
}

variable "db_user" {
  type    = string
  default = "dashverse"
}

variable "secret_name" {
  type = string
}

variable "password_key" {
  type    = string
  default = "postgres-password"
}

variable "storage_size" {
  type    = string
  default = "10Gi"
}

variable "storage_class" {
  type    = string
  default = "standard"
}

variable "cpu_limit" {
  type    = string
  default = "1000m"
}

variable "memory_limit" {
  type    = string
  default = "2Gi"
}

variable "cpu_request" {
  type    = string
  default = "250m"
}

variable "memory_request" {
  type    = string
  default = "512Mi"
}

variable "init_configmap" {
  type    = string
  default = "db-init-schema"
}
