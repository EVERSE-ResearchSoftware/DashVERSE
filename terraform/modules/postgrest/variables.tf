variable "namespace" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = { app = "dashverse" }
}

variable "image" {
  type    = string
  default = "postgrest/postgrest:v12.2.3"
}

variable "replicas" {
  type    = number
  default = 1
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

variable "db_schema" {
  type    = string
  default = "api"
}

variable "anon_role" {
  type    = string
  default = "web_anon"
}

variable "secret_name" {
  type = string
}

variable "password_key" {
  type    = string
  default = "postgres-password"
}

variable "jwt_secret_key" {
  type    = string
  default = ""
}
