resource "kubernetes_config_map" "sync_scripts" {
  metadata {
    name      = "sync-scripts"
    namespace = var.namespace
  }

  data = {
    "sync.sh" = <<-EOF
      #!/bin/sh
      set -e

      # install curl and jq
      apk add --no-cache curl jq >/dev/null 2>&1

      GITHUB_RAW="https://raw.githubusercontent.com/EVERSE-ResearchSoftware/indicators/main"
      GITHUB_API="https://api.github.com/repos/EVERSE-ResearchSoftware/indicators/contents"
      WORKDIR="/tmp/sync"

      mkdir -p $WORKDIR/dimensions $WORKDIR/indicators

      echo "Fetching dimensions..."
      for dim in $(curl -sf "$GITHUB_API/dimensions" | jq -r '.[].name | select(endswith(".json"))'); do
        curl -sfL "$GITHUB_RAW/dimensions/$dim" -o "$WORKDIR/dimensions/$dim"
      done

      echo "Fetching indicators..."
      for ind in $(curl -sf "$GITHUB_API/indicators" | jq -r '.[].name | select(endswith(".json"))'); do
        curl -sfL "$GITHUB_RAW/indicators/$ind" -o "$WORKDIR/indicators/$ind"
      done

      echo "Generating SQL..."
      cat > $WORKDIR/import.sql <<EOSQL
      SET search_path TO api, public;
      EOSQL

      for f in $WORKDIR/dimensions/*.json; do
        abbrev=$(jq -r '.abbreviation // empty' "$f")
        name=$(jq -r '.name // empty' "$f")
        desc=$(jq -r '.description // empty' "$f" | sed "s/'/''/g")
        source=$(jq -c '.source // {}' "$f")

        if [ -n "$abbrev" ] && [ -n "$name" ]; then
          cat >> $WORKDIR/import.sql <<EOSQL
      INSERT INTO dimensions (identifier, name, description, status, source)
      VALUES ('$abbrev', '$name', '$desc', 'Active', '$source'::jsonb)
      ON CONFLICT (identifier) DO UPDATE SET
        name = EXCLUDED.name, description = EXCLUDED.description,
        source = EXCLUDED.source, updated_at = CURRENT_TIMESTAMP;
      EOSQL
        fi
      done

      for f in $WORKDIR/indicators/*.json; do
        abbrev=$(jq -r '.abbreviation // empty' "$f")
        name=$(jq -r '.name // empty' "$f")
        desc=$(jq -r '.description // empty' "$f" | sed "s/'/''/g")
        status=$(jq -r '.status // "Active"' "$f")
        dim=$(jq -r '.qualityDimension // empty' "$f")
        contact=$(jq -c '.contact // .contactPoint // {}' "$f")
        source=$(jq -c '.source // {}' "$f")

        if [ -n "$abbrev" ] && [ -n "$name" ]; then
          cat >> $WORKDIR/import.sql <<EOSQL
      INSERT INTO indicators (identifier, name, description, status, quality_dimension, contact, source)
      VALUES ('$abbrev', '$name', '$desc', '$status', '$dim', '$contact'::jsonb, '$source'::jsonb)
      ON CONFLICT (identifier) DO UPDATE SET
        name = EXCLUDED.name, description = EXCLUDED.description, status = EXCLUDED.status,
        quality_dimension = EXCLUDED.quality_dimension, contact = EXCLUDED.contact,
        source = EXCLUDED.source, updated_at = CURRENT_TIMESTAMP;
      EOSQL
        fi
      done

      echo "Importing to database..."
      PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f $WORKDIR/import.sql

      echo "Sync complete"
    EOF
  }
}

resource "kubernetes_cron_job_v1" "sync" {
  metadata {
    name      = "everse-sync"
    namespace = var.namespace
  }

  spec {
    schedule                      = var.sync_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 1

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            restart_policy = "OnFailure"

            container {
              name    = "sync"
              image   = "postgres:17-alpine"
              command = ["/bin/sh", "/scripts/sync.sh"]

              env {
                name  = "DB_HOST"
                value = var.db_host
              }
              env {
                name  = "DB_NAME"
                value = var.db_name
              }
              env {
                name  = "DB_USER"
                value = var.db_user
              }
              env {
                name = "DB_PASSWORD"
                value_from {
                  secret_key_ref {
                    name = var.secrets_name
                    key  = "postgres-password"
                  }
                }
              }

              volume_mount {
                name       = "scripts"
                mount_path = "/scripts"
              }
            }

            volume {
              name = "scripts"
              config_map {
                name         = kubernetes_config_map.sync_scripts.metadata[0].name
                default_mode = "0755"
              }
            }
          }
        }
      }
    }
  }
}
