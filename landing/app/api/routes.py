from fastapi import APIRouter, Request, HTTPException, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os
import json
import urllib.parse

from app.core.config import settings

router = APIRouter()

templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

DASHBOARDS = {
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
    }
}


def _software_detail_response(request: Request, name: str):
    superset_base = settings.superset_external_url or ""

    rison_filter = (
        "(NATIVE_FILTER-software:(filterState:(value:!('"
        + name.replace("'", "\\'")
        + "'))))"
    )
    encoded_filter = urllib.parse.quote(rison_filter, safe="")

    embed_url = (
        f"{superset_base}/superset/dashboard/researcher-who-codes/"
        f"?standalone=2&native_filters={encoded_filter}"
    ) if superset_base else ""

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "slug": "researcher-who-codes",
            "dashboard": {
                "title": f"Software: {name}",
                "description": f"Quality assessment results for {name}.",
                "audience": "Per-software view",
                "rsqkit_url": "https://everse.software/RSQKit/researcher_who_codes",
            },
            "embed_url": embed_url,
            "encoded_software_filter": encoded_filter,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": "researcher-who-codes",
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
