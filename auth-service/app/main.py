from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import settings
from app.core.database import engine, Base
from app.core.logging_config import configure_logging
from app.api import auth, tokens, web

# Configure logging with automatic secret masking
configure_logging(level=settings.LOG_LEVEL)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up auth-service...")

    # Create database tables
    logger.info("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")

    yield
    logger.info("Shutting down auth-service...")


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

# Register API routers
app.include_router(auth.router)
app.include_router(tokens.router)
app.include_router(web.router)


@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
async def health_check():
    """
    Health check endpoint for Kubernetes liveness and readiness probes.
    """
    return {
        "status": "healthy",
        "service": "auth-service",
        "version": "1.0.0"
    }


@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint providing service information.
    """
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
    """
    Global exception handler for unhandled exceptions.
    """
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
