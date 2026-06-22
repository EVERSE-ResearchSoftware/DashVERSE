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
    # Public role inherits Gamma's read-only permissions so the embedded
    # SDK can call /api/v1/dashboard/* and /api/v1/chart/* to render
    # iframes. The UI list pages and any write operations are then
    # explicitly revoked in
    # ansible/roles/superset_config/tasks/permissions.yml.
    PUBLIC_ROLE_LIKE = "Gamma"
    FAB_ADD_SECURITY_API = True
    FEATURE_FLAGS = {
        "EMBEDDED_SUPERSET": True,
        "DASHBOARD_RBAC": True,
        # render advanced_data_type: url columns as clickable links in tables
        "ENABLE_ADVANCED_DATA_TYPES": True
    }
  data_cache: |
    # Redis-backed chart-data cache. Without it every chart on a dashboard
    # round-trips through superset, sqlalchemy and postgres on every load,
    # which is the dominant latency for the prod /dashboard pages (~1s per
    # chart with 9+ charts loaded in parallel). The frontend's
    # /superset/refresh endpoint invalidates the project-aware datasets
    # after bulk loads (see _superset_invalidate_datasets in routes.py), so
    # newly ingested assessments still appear immediately. Ad-hoc chart
    # config edits made directly in the Superset UI won't be visible until
    # CACHE_DEFAULT_TIMEOUT expires or /superset/refresh is called.
    CACHE_REDIS_HOST = "superset-redis-headless"
    CACHE_REDIS_PORT = 6379
    CACHE_REDIS_DB = 1
    DATA_CACHE_CONFIG = {
        "CACHE_TYPE": "RedisCache",
        # short TTL so visibility / assessment edits surface within a
        # minute when the explicit /superset/refresh hook is missed
        # (e.g. direct DB writes, NOTIFY race). Long enough to absorb
        # the bursty page-load fan-out of N charts per dashboard.
        "CACHE_DEFAULT_TIMEOUT": 60,
        "CACHE_KEY_PREFIX": "superset_data_",
        "CACHE_REDIS_HOST": CACHE_REDIS_HOST,
        "CACHE_REDIS_PORT": CACHE_REDIS_PORT,
        "CACHE_REDIS_DB": CACHE_REDIS_DB,
    }
  anon_list_lockout: |
    # The Public role still has Gamma's read permission on Chart, Dashboard
    # and Dataset REST APIs (needed by the embedded SDK for chart-config
    # fetches), so revoking can_list alone doesn't stop the React SPA at
    # /chart/list, /dashboard/list, /tablemodelview/list from populating
    # itself client-side. A Flask before_request hook handles those routes
    # explicitly: anonymous viewers get bounced to /login, embedded SDK
    # API calls under /api/v1/* keep working.
    def FLASK_APP_MUTATOR(app):
        from flask import redirect, request
        from flask_login import current_user

        PROTECTED_PREFIXES = (
            "/chart/list",
            "/dashboard/list",
            "/tablemodelview/list",
            "/databaseview/list",
            "/annotationlayer/list",
            "/csstemplatemodelview/list",
            "/tagmodelview/list",
            "/savedqueryview/list",
            "/logmodelview/list",
            "/users/list",
            "/roles/list",
        )

        @app.before_request
        def _block_anon_from_lists():
            try:
                if current_user.is_authenticated:
                    return None
            except Exception:
                return None
            path = request.path.rstrip("/")
            if any(path == p or path.startswith(p + "/") for p in PROTECTED_PREFIXES):
                return redirect("/login/?next=" + request.full_path)
            return None

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
