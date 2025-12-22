from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import logging

from app.api.routes import router
from app.core.config import settings

logging.basicConfig(level=getattr(logging, settings.log_level))
logger = logging.getLogger(__name__)

app = FastAPI(
    title="DashVERSE Demo Portal",
    description="Public demo portal for viewing embedded Superset dashboards",
    version="1.0.0",
    root_path=settings.root_path,
)

@app.middleware("http")
async def redirect_to_www(request, call_next):
    host = request.headers.get("host")
    if host == "dashverse.cloud":
        url = request.url.replace(hostname="www.dashverse.cloud")
        return RedirectResponse(url=str(url), status_code=301)
    response = await call_next(request)
    return response

origins = [
    "https://dashverse.cloud",
    "https://www.dashverse.cloud",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

app.include_router(router)


@app.get("/health")
async def health():
    return JSONResponse({"status": "healthy"})


@app.on_event("startup")
async def startup():
    logger.info(f"Demo portal starting, superset_url={settings.superset_url}")
