from fastapi import APIRouter, Request, HTTPException, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os
import json
import time
import logging
import urllib.parse
import urllib.request
import urllib.error

from app.core.config import settings

router = APIRouter()
log = logging.getLogger(__name__)

_SUPERSET_ADMIN_USER = os.environ.get("SUPERSET_ADMIN_USER", "")
_SUPERSET_ADMIN_PASSWORD = os.environ.get("SUPERSET_ADMIN_PASSWORD", "")

_token_cache = {"token": None, "expires_at": 0.0}


def _superset_token() -> str | None:
    if not _SUPERSET_ADMIN_PASSWORD or not settings.superset_url:
        return None
    now = time.time()
    if _token_cache["token"] and _token_cache["expires_at"] > now + 30:
        return _token_cache["token"]
    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/security/login",
            data=json.dumps({
                "username": _SUPERSET_ADMIN_USER or "admin",
                "password": _SUPERSET_ADMIN_PASSWORD,
                "provider": "db",
                "refresh": True,
            }).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        token = body.get("access_token")
        if token:
            _token_cache["token"] = token
            _token_cache["expires_at"] = now + 5 * 60
            return token
    except Exception as exc:
        log.warning("Superset login failed: %s", exc)
    return None


_dashboard_id_cache: dict[str, int] = {}


def _dashboard_id(slug: str, token: str) -> int | None:
    if slug in _dashboard_id_cache:
        return _dashboard_id_cache[slug]
    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/dashboard/{slug}",
            headers={"Authorization": f"Bearer {token}"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        did = body.get("result", {}).get("id")
        if isinstance(did, int):
            _dashboard_id_cache[slug] = did
            return did
    except Exception as exc:
        log.warning("dashboard lookup failed for %s: %s", slug, exc)
    return None


def _filter_state_key(dashboard_slug: str, filter_state: dict) -> str | None:
    token = _superset_token()
    if not token:
        return None
    did = _dashboard_id(dashboard_slug, token)
    if did is None:
        return None
    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/dashboard/{did}/filter_state",
            data=json.dumps({"value": json.dumps(filter_state)}).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        return body.get("key")
    except Exception as exc:
        log.warning("filter_state POST failed: %s", exc)
        return None

templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

DASHBOARDS = {
    "global": {
        "title": "Global Overview",
        "description": "Portfolio-wide quality assessment activity plus the EVERSE quality model catalog. Aggregate counts and rates; no software or project names are exposed.",
        "audience": "Anyone — open to anonymous visitors",
        "rsqkit_url": "",
    },
    "policy-maker": {
        "title": "Policy Maker",
        "description": "High-level metrics on software quality adoption and FAIR compliance across organizations.",
        "audience": "Funding agencies, research institutions, governmental bodies",
        "rsqkit_url": "https://everse.software/RSQKit/policy_maker"
    },
    "principal-investigator": {
        "title": "Principal Investigator",
        "description": "Project-level metrics, software management insights, and areas requiring attention.",
        "audience": "Research project leaders managing software development",
        "rsqkit_url": "https://everse.software/RSQKit/principal_investigator"
    },
    "research-software-engineer": {
        "title": "Research Software Engineer",
        "description": "Technical metrics, code quality indicators, and detailed assessment results.",
        "audience": "Professionals specializing in research software development",
        "rsqkit_url": "https://everse.software/RSQKit/research_software_engineer"
    },
    "researcher-who-codes": {
        "title": "Researcher Who Codes",
        "description": "Practical guidance on quality improvements without requiring deep engineering expertise.",
        "audience": "Scientists developing software as part of their research",
        "rsqkit_url": "https://everse.software/RSQKit/researcher_who_codes"
    },
    "trainer": {
        "title": "Trainer",
        "description": "Common issues, skill gaps, and areas where training can have the most impact.",
        "audience": "Educators teaching research software development and quality",
        "rsqkit_url": "https://everse.software/RSQKit/trainer"
    },
    "software-detail": {
        "title": "Software Detail",
        "description": "Per-software view: KPIs, quality trend, dimension profile, comparison to portfolio median, failed checks, improvement targets, and assessment history. Pick a project from the Software dropdown.",
        "audience": "Anyone reviewing a single software project",
        "rsqkit_url": ""
    },
    "catalog": {
        "title": "Catalog",
        "description": "EVERSE quality model reference: catalog size, coverage by assessments, and the full list of dimensions and indicators with their definitions.",
        "audience": "Anyone learning the quality model or planning what to assess next",
        "rsqkit_url": ""
    }
}


def _software_detail_response(request: Request, name: str):
    superset_base = settings.superset_external_url or ""

    filter_state = {
        "NATIVE_FILTER-software": {
            "id": "NATIVE_FILTER-software",
            "extraFormData": {
                "filters": [{"col": "software_name", "op": "IN", "val": [name]}]
            },
            "filterState": {"value": [name]},
        }
    }
    permalink_key = _filter_state_key("software-detail", filter_state)

    val = name.replace("'", "\\'")
    rison_filter = (
        "(NATIVE_FILTER-software:("
        "id:NATIVE_FILTER-software,"
        f"filterState:(value:!('{val}')),"
        f"extraFormData:(filters:!((col:software_name,op:IN,val:!('{val}'))))"
        "))"
    )
    encoded_filter = urllib.parse.quote(rison_filter, safe="")

    if permalink_key:
        embed_url = (
            f"{superset_base}/superset/dashboard/software-detail/"
            f"?standalone=2&native_filters_key={permalink_key}"
        ) if superset_base else ""
    else:
        embed_url = (
            f"{superset_base}/superset/dashboard/software-detail/"
            f"?standalone=2&native_filters={encoded_filter}"
        ) if superset_base else ""

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "slug": "software-detail",
            "dashboard": {
                "title": f"Software: {name}",
                "description": f"Quality assessment results for {name}.",
                "audience": "Per-software view",
                "rsqkit_url": "https://everse.software/RSQKit/researcher_who_codes",
            },
            "embed_url": embed_url,
            "encoded_software_filter": encoded_filter,
            "native_filters_key": permalink_key,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": "software-detail",
            "software_name": name,
        }
    )


@router.get("/", response_class=HTMLResponse)
async def home(request: Request, software: str | None = Query(default=None)):
    if software:
        return _software_detail_response(request, software)
    return templates.TemplateResponse(
        "home.html",
        {
            "request": request,
            "dashboards": DASHBOARDS,
            "superset_url": settings.superset_url,
            "current_dashboard": None
        }
    )


@router.get("/software/{name}", response_class=HTMLResponse)
async def software_detail(request: Request, name: str):
    return _software_detail_response(request, name)


@router.get("/concepts", response_class=HTMLResponse)
async def concepts(request: Request):
    assessment_example = {
        "@context": "https://w3id.org/everse/rsqa/0.0.1/",
        "@type": "SoftwareQualityAssessment",
        "name": "Quality Assessment for CFFinit v2.3.1",
        "description": "An automated assessment of the CFFinit tool based on the EVERSE software quality indicators, run on 2025-06-19.",
        "creator": {
            "@type": "schema:Person",
            "name": "Faruk Diblen",
            "email": "f.diblen@example.com"
        },
        "dateCreated": "2025-06-19T17:52:00Z",
        "license": {"@id": "https://creativecommons.org/publicdomain/zero/1.0/"},
        "assessedSoftware": {
            "@type": "schema:SoftwareApplication",
            "name": "CFFinit",
            "softwareVersion": "2.3.1",
            "url": "https://github.com/citation-file-format/cff-initializer-javascript",
            "schema:identifier": {
                "@id": "https://doi.org/10.5281/zenodo.8224012"
            }
        },
        "checks": [
            {
                "@type": "CheckResult",
                "assessesIndicator": {"@id": "https://w3id.org/everse/i/indicators/license"},
                "checkingSoftware": {
                    "@type": "schema:SoftwareApplication",
                    "name": "howfairis",
                    "@id": "https://w3id.org/everse/tools/howfairis",
                    "softwareVersion": "0.14.2"
                },
                "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
                "status": {"@id": "schema:CompletedActionStatus"},
                "output": "true",
                "evidence": "Found license file: 'LICENSE'."
            },
            {
                "@type": "CheckResult",
                "assessesIndicator": {"@id": "https://w3id.org/everse/i/indicators/citation"},
                "checkingSoftware": {
                    "@type": "schema:SoftwareApplication",
                    "name": "howfairis",
                    "@id": "https://w3id.org/everse/tools/howfairis",
                    "softwareVersion": "0.14.2"
                },
                "process": "Searches for a 'CITATION.cff' file in the repository root and validates its syntax.",
                "status": {"@id": "schema:CompletedActionStatus"},
                "output": "valid",
                "evidence": "Found valid CITATION.cff file in repository root."
            }
        ]
    }

    assessment_example_json = json.dumps(assessment_example, indent=2)

    return templates.TemplateResponse(
        "concepts.html",
        {
            "request": request,
            "dashboards": DASHBOARDS,
            "current_dashboard": None,
            "assessment_example": assessment_example_json,
        },
    )


@router.get("/dashboard/{slug}", response_class=HTMLResponse)
async def dashboard(request: Request, slug: str):
    if slug not in DASHBOARDS:
        raise HTTPException(status_code=404, detail="Dashboard not found")

    dashboard_info = DASHBOARDS[slug]

    superset_base = settings.superset_external_url or ""
    embed_url = f"{superset_base}/superset/dashboard/{slug}/?standalone=2" if superset_base else ""

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "slug": slug,
            "dashboard": dashboard_info,
            "embed_url": embed_url,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": slug
        }
    )
