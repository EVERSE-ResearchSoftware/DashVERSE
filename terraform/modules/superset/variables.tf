variable "namespace" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "0.13.3"
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type    = string
  default = "dashverse"
}

variable "db_user" {
  type    = string
  default = "dashverse"
}

variable "db_pass" {
  type      = string
  sensitive = true
}

variable "secret_name" {
  type = string
}

variable "password_key" {
  type    = string
  default = "postgres-password"
}

variable "superset_secret_key" {
  type    = string
  default = "superset-secret-key"
}

variable "admin_password" {
  description = "Superset admin password"
  type        = string
  sensitive   = true
}
