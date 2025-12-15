from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os

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
