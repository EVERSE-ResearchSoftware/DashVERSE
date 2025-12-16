from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os
import json

router = APIRouter()

templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

# dashboard definitions based on RSQKit roles
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


@router.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse(
        "home.html",
        {
            "request": request,
            "dashboards": DASHBOARDS,
            "current_dashboard": None
        }
    )


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


@router.get("/data", response_class=HTMLResponse)
async def data(request: Request):
    return templates.TemplateResponse(
        "data.html",
        {
            "request": request,
            "dashboards": DASHBOARDS,
            "current_dashboard": None,
        },
    )


@router.get("/dashboard/{slug}", response_class=HTMLResponse)
async def dashboard(request: Request, slug: str):
    if slug not in DASHBOARDS:
        raise HTTPException(status_code=404, detail="Dashboard not found")

    dashboard_info = DASHBOARDS[slug]

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "slug": slug,
            "dashboard": dashboard_info,
            "embed_url": "",
            "superset_external_url": "",
            "dashboards": DASHBOARDS,
            "current_dashboard": slug
        }
    )
