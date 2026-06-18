variable "namespace" {
  description = "Kubernetes namespace where postgresql runs"
  type        = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "postgres_image" {
  description = "Image used to run psql / pg_isready inside the job"
  type        = string
  default     = "postgres:17-alpine"
}

variable "secret_name" {
  description = "Secret holding the postgres superuser password"
  type        = string
}

variable "password_key" {
  description = "Key within secret_name for the postgres password"
  type        = string
  default     = "postgres-password"
}

variable "db_user" {
  description = "Postgres superuser whose credentials apply the schema"
  type        = string
}

variable "db_name" {
  description = "Database name to apply the schema against"
  type        = string
}

variable "init_configmap" {
  description = "ConfigMap holding 01-*.sql ... 07-*.sql"
  type        = string
}

variable "schema_files" {
  description = <<-EOT
    Filenames (in mount order) the job will apply via psql, relative to
    the mounted configmap. Lets the apply order stay in sync with the
    db-init module without re-reading the files here.
  EOT
  type        = list(string)
  default = [
    "01-schema.sql",
    "02-tables.sql",
    "03-indexes.sql",
    "04-triggers.sql",
    "08-visibility.sql",
    "05-rls.sql",
    "06-views.sql",
    "07-permissions.sql",
  ]
}

variable "schema_hash" {
  description = <<-EOT
    Short hash derived from the SQL files. The job name embeds this so a
    fresh job is created (and the old one's status is replaced) whenever
    the schema changes.
  EOT
  type        = string
}
