service:
  type: ClusterIP
  port: 8088

supersetNode:
  replicaCount: 1
  connections:
    db_host: "${db_host}"
    db_port: "${db_port}"
    db_user: "${db_user}"
    db_pass: "${db_pass}"
    db_name: "${db_name}"

supersetWorker:
  enabled: true
  replicaCount: 1
  resources:
    limits:
      cpu: "1000m"
      memory: "2Gi"
    requests:
      cpu: "500m"
      memory: "1Gi"
  command:
    - "/bin/sh"
    - "-c"
    - ". /app/pythonpath/superset_bootstrap.sh; celery --app=superset.tasks.celery_app:app worker --concurrency=4"

supersetCeleryBeat:
  enabled: true

postgresql:
  enabled: false

redis:
  enabled: true
  image:
    registry: docker.io
    repository: redis
    tag: "7.4"
  master:
    persistence:
      enabled: false

configOverrides:
  secret: |
    import os
    SECRET_KEY = os.environ.get('SECRET_KEY', '')
    SQLALCHEMY_DATABASE_URI = f"postgresql://{os.environ.get('DB_USER')}:{os.environ.get('DB_PASS')}@{os.environ.get('DB_HOST')}:{os.environ.get('DB_PORT')}/{os.environ.get('DB_NAME')}"
  embedding: |
    # allow dashboard embedding in iframes
    ENABLE_CORS = True
    CORS_OPTIONS = {
        "supports_credentials": True,
        "allow_headers": ["*"],
        "resources": ["*"],
        "origins": ["*"]
    }
    # disable Talisman security headers to allow iframe embedding
    TALISMAN_ENABLED = False
    WTF_CSRF_ENABLED = False
    HTTP_HEADERS = {"X-Frame-Options": "ALLOWALL"}
    PUBLIC_ROLE_LIKE = "Gamma"
    FAB_ADD_SECURITY_API = True
    FEATURE_FLAGS = {
        "EMBEDDED_SUPERSET": True,
        "DASHBOARD_RBAC": True
    }

extraEnv:
  DB_HOST: "${db_host}"
  DB_PORT: "${db_port}"
  DB_USER: "${db_user}"
  DB_NAME: "${db_name}"

extraEnvRaw:
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: "${secret_name}"
        key: "${password_key}"
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: "${secret_name}"
        key: "${superset_secret_key}"

init:
  enabled: true
  createAdmin: true
  adminUser:
    username: admin
    firstname: Admin
    lastname: User
    email: admin@dashverse.local
    password: "${admin_password}"

bootstrapScript: |
  #!/bin/bash
  set -e
  echo "Installing dependencies..."
  pip install psycopg2-binary flask-cors
  echo "Waiting for PostgreSQL..."
  until python -c "import socket; s=socket.socket(); s.settimeout(5); exit(0 if s.connect_ex(('$DB_HOST', int('$DB_PORT'))) == 0 else 1); s.close()" 2>/dev/null; do
    sleep 2
  done
  echo "Waiting for Redis..."
  until python -c "import socket; s=socket.socket(); s.settimeout(5); exit(0 if s.connect_ex(('superset-redis-headless', 6379)) == 0 else 1); s.close()" 2>/dev/null; do
    sleep 2
  done
  echo "Running database migrations..."
  superset db upgrade
  superset init
  echo "Bootstrap complete"
