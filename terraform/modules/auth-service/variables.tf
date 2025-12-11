variable "namespace_name" {
  description = "Kubernetes namespace for auth-service deployment"
  type        = string
}

variable "auth_service_image" {
  description = "Docker image for auth-service"
  type        = string
  default     = "dashverse/auth-service:latest"
}

variable "replicas" {
  description = "Number of auth-service replicas"
  type        = number
  default     = 1
}

variable "secret_name" {
  description = "Name of Kubernetes secret containing credentials"
  type        = string
}

variable "postgres_host" {
  description = "PostgreSQL service hostname"
  type        = string
}

variable "postgres_port" {
  description = "PostgreSQL service port"
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dashverse"
}

variable "database_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "dashverse"
}

variable "postgres_password_key" {
  description = "Key name for PostgreSQL password in the secret"
  type        = string
  default     = "postgres-password"
}

variable "jwt_secret_key" {
  description = "Key name for JWT secret in the secret"
  type        = string
  default     = "jwt-secret"
}

variable "jwt_expiration_days" {
  description = "JWT token expiration in days"
  type        = number
  default     = 30
}

variable "password_min_length" {
  description = "Minimum password length for user registration"
  type        = number
  default     = 12
}

variable "max_login_attempts" {
  description = "Maximum failed login attempts before lockout"
  type        = number
  default     = 5
}

variable "lockout_duration_minutes" {
  description = "Account lockout duration in minutes after max failed attempts"
  type        = number
  default     = 15
}

variable "log_level" {
  description = "Application log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cpu_limit" {
  description = "CPU limit for auth-service container"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for auth-service container"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for auth-service container"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for auth-service container"
  type        = string
  default     = "256Mi"
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "module_depends_on" {
  description = "List of modules this depends on"
  type        = any
  default     = []
}
