from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlalchemy import text
import logging

from app.core.config import settings
from app.core.database import engine, Base
from app.core.logging_config import configure_logging
from app.api import auth, tokens, projects, stats

configure_logging(level=settings.LOG_LEVEL)

logger = logging.getLogger(__name__)


_VISIBILITY_MIGRATION_SQL = """
DO $$
BEGIN
  -- auth.projects -------------------------------------------------------
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema = 'auth' AND table_name = 'projects') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'auth' AND table_name = 'projects'
                     AND column_name = 'visibility') THEN
      ALTER TABLE auth.projects ADD COLUMN visibility TEXT;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'projects'
                 AND column_name = 'is_public') THEN
      UPDATE auth.projects
         SET visibility = CASE WHEN is_public THEN 'public' ELSE 'private' END
       WHERE visibility IS NULL;
    END IF;
    UPDATE auth.projects SET visibility = 'private' WHERE visibility IS NULL;
    ALTER TABLE auth.projects ALTER COLUMN visibility SET NOT NULL;
    ALTER TABLE auth.projects ALTER COLUMN visibility SET DEFAULT 'public';
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints
                   WHERE constraint_schema = 'auth'
                     AND constraint_name = 'projects_visibility_check') THEN
      ALTER TABLE auth.projects
        ADD CONSTRAINT projects_visibility_check
        CHECK (visibility IN ('private','authenticated','public'));
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'projects'
                 AND column_name = 'is_public') THEN
      ALTER TABLE auth.projects DROP COLUMN is_public;
    END IF;
  END IF;

  -- auth.software_visibility -------------------------------------------
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema = 'auth' AND table_name = 'software_visibility') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                     AND column_name = 'visibility') THEN
      ALTER TABLE auth.software_visibility ADD COLUMN visibility TEXT;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                 AND column_name = 'is_public') THEN
      UPDATE auth.software_visibility
         SET visibility = CASE WHEN is_public THEN 'public' ELSE 'private' END
       WHERE visibility IS NULL;
    END IF;
    UPDATE auth.software_visibility SET visibility = 'private' WHERE visibility IS NULL;
    ALTER TABLE auth.software_visibility ALTER COLUMN visibility SET NOT NULL;
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints
                   WHERE constraint_schema = 'auth'
                     AND constraint_name = 'software_visibility_visibility_check') THEN
      ALTER TABLE auth.software_visibility
        ADD CONSTRAINT software_visibility_visibility_check
        CHECK (visibility IN ('private','authenticated','public'));
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'software_visibility'
                 AND column_name = 'is_public') THEN
      ALTER TABLE auth.software_visibility DROP COLUMN is_public;
    END IF;
  END IF;
END
$$;
"""


def _run_visibility_migration() -> None:
    with engine.begin() as conn:
        conn.execute(text("SELECT pg_advisory_xact_lock(7726334)"))
        conn.execute(text(_VISIBILITY_MIGRATION_SQL))


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up backend...")

    logger.info("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")

    logger.info("Applying visibility migration...")
    _run_visibility_migration()
    logger.info("Visibility migration applied")

    yield
    logger.info("Shutting down backend...")


app = FastAPI(
    title="DashVERSE Auth Service",
    description="Authentication service for DashVERSE - the research software quality dashboard. "
                "Provides user registration, login, and JWT token management for secure API access. "
                "Generated tokens can be used to authenticate requests to the DashVERSE REST API.",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(tokens.router)
app.include_router(projects.router)
app.include_router(stats.router)


@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "backend",
        "version": "1.0.0"
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "service": "DashVERSE Auth Service",
        "version": "1.0.0",
        "description": "JWT-based authentication service",
        "endpoints": {
            "health": "/health",
            "api_docs": "/docs",
            "openapi": "/openapi.json"
        },
        "api": {
            "authentication": {
                "register": "POST /api/auth/register",
                "login": "POST /api/auth/login"
            },
            "tokens": {
                "generate": "POST /api/tokens/",
                "list": "GET /api/tokens/",
                "revoke": "POST /api/tokens/revoke",
                "delete": "DELETE /api/tokens/{token_id}"
            }
        }
    }


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
