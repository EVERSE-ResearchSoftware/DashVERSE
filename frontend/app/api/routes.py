from fastapi import APIRouter, Request, HTTPException, Query, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
import asyncio
import os
import json
import time
import logging
import urllib.parse
import urllib.request
import urllib.error

import httpx

from app.core.config import settings
from app.core.auth import current_user

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

_embedded_uuid_cache: dict[str, str] = {}
_dataset_id_cache: dict[str, int] = {}


def _dataset_id_by_name(name: str, token: str) -> int | None:
    if name in _dataset_id_cache:
        return _dataset_id_cache[name]
    try:
        q = urllib.parse.quote(
            f"(filters:!((col:table_name,opr:eq,value:{name})))",
            safe="",
        )
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/dataset/?q={q}",
            headers={"Authorization": f"Bearer {token}"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        result = body.get("result") or []
        if result:
            did = result[0]["id"]
            _dataset_id_cache[name] = did
            return did
    except Exception as exc:
        log.warning("dataset id lookup failed for %s: %s", name, exc)
    return None


def _embedded_dashboard_uuid(slug: str) -> str | None:
    if slug in _embedded_uuid_cache:
        return _embedded_uuid_cache[slug]
    token = _superset_token()
    if not token:
        return None
    did = _dashboard_id(slug, token)
    if did is None:
        return None
    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/dashboard/{did}/embedded",
            headers={"Authorization": f"Bearer {token}"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        u = body.get("result", {}).get("uuid")
        if u:
            _embedded_uuid_cache[slug] = u
            return u
    except Exception as exc:
        log.warning("embedded uuid lookup failed for %s: %s", slug, exc)
    return None


def _superset_guest_token_for(slug: str, user: dict | None) -> str | None:
    token = _superset_token()
    if not token:
        return None
    embedded_uuid = _embedded_dashboard_uuid(slug)
    if not embedded_uuid:
        return None

    uid = None
    if user:
        try:
            uid = int(user.get("sub")) if user.get("sub") is not None else None
        except (TypeError, ValueError):
            uid = None

    if uid is not None:
        checks_clause = (
            "effective_visibility IN ('public', 'authenticated') "
            f"OR author_user_id = {uid}"
        )
        proj_clause = (
            "visibility IN ('public', 'authenticated') "
            f"OR owner_user_id = {uid}"
        )
    else:
        checks_clause = "effective_visibility = 'public'"
        proj_clause = "visibility = 'public'"

    rls: list[dict] = []
    checks_did = _dataset_id_by_name("assessment_checks", token)
    if checks_did is not None:
        rls.append({"dataset": checks_did, "clause": checks_clause})
    proj_did = _dataset_id_by_name("projects", token)
    if proj_did is not None:
        rls.append({"dataset": proj_did, "clause": proj_clause})

    payload = {
        "user": {
            "username": (user or {}).get("username") or "anonymous",
            "first_name": "",
            "last_name": "",
        },
        "resources": [{"type": "dashboard", "id": embedded_uuid}],
        "rls": rls,
    }

    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/security/guest_token/",
            data=json.dumps(payload).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
        return body.get("token")
    except Exception as exc:
        log.warning("Superset guest_token mint failed: %s", exc)
        return None


def _superset_invalidate_datasets(uuids: list[str]) -> None:
    if not uuids:
        return
    token = _superset_token()
    if not token:
        return
    try:
        req = urllib.request.Request(
            f"{settings.superset_url}/api/v1/cachekey/invalidate",
            data=json.dumps({
                "datasource_uids": [f"{u}__table" for u in uuids],
            }).encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
            },
            method="POST",
        )
        urllib.request.urlopen(req, timeout=5)
    except Exception as exc:
        log.warning("Superset cache invalidate failed: %s", exc)


_PROJECT_AWARE_DATASET_UUIDS = [
    "36f136b1-53e0-41c9-9f21-180bdea10683",
    "9ccd1028-35e4-4b23-9d3b-178fac4ed156",
    "4372e3b3-6fa2-4369-b068-74204fa4d16f",
    "3a34e152-6e74-46ce-8f6c-14189a402411",
]


templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

DASHBOARDS = {
    "global": {
        "title": "Overview",
        "description": "Portfolio-wide outcome distribution, monthly assessment activity, top failing indicators and checking-tool usage. Anonymous-safe: no software or project names are exposed.",
        "audience": "Open to anonymous visitors. No login required.",
        "rsqkit_url": "",
        "hide_filters": True,
    },
    "assessments": {
        "title": "Assessments",
        "description": "Quality profile and improvement targets for every assessment you can see. Per-software outcome breakdown, dimension profile, outcomes heatmap, ranked failing indicators, and recent assessments. Filter by project, software, dimension, outcome, or date.",
        "audience": "Authenticated users only. The view narrows automatically to the scope you're allowed to see.",
        "rsqkit_url": "",
        "auth_required": True,
    },
    "catalog": {
        "title": "Catalog",
        "description": "Reference view of the EVERSE quality model: catalog size, how much of it has been exercised by assessments, coverage per checking tool, and the full list of dimensions and indicators.",
        "audience": "Authenticated users only.",
        "rsqkit_url": "",
        "auth_required": True,
        "hide_filters": True,
    },
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
    permalink_key = _filter_state_key("assessments", filter_state)

    val = name.replace("'", "\\'")
    rison_filter = (
        "(NATIVE_FILTER-software:("
        "id:NATIVE_FILTER-software,"
        f"filterState:(value:!('{val}')),"
        f"extraFormData:(filters:!((col:software_name,op:IN,val:!('{val}'))))"
        "))"
    )
    encoded_filter = urllib.parse.quote(rison_filter, safe="")

    embed_url = (
        f"{superset_base}/superset/dashboard/assessments/?standalone=2"
        if superset_base else ""
    )

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "user": current_user(request),
            "slug": "assessments",
            "dashboard": {
                "title": f"Software: {name}",
                "description": f"Quality assessment results for {name}.",
                "audience": "Per-software view",
                "rsqkit_url": "https://everse.software/RSQKit/researcher_who_codes",
                "hide_filters": True,
            },
            "embed_url": embed_url,
            "encoded_software_filter": encoded_filter,
            "native_filters_key": permalink_key,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": "assessments",
            "software_name": name,
        }
    )


def _project_detail_response(request: Request, name: str):
    superset_base = settings.superset_external_url or ""

    filter_state = {
        "NATIVE_FILTER-project": {
            "id": "NATIVE_FILTER-project",
            "extraFormData": {
                "filters": [{"col": "project_name", "op": "IN", "val": [name]}]
            },
            "filterState": {"value": [name]},
        }
    }
    permalink_key = _filter_state_key("assessments", filter_state)

    val = name.replace("'", "\\'")
    rison_filter = (
        "(NATIVE_FILTER-project:("
        "id:NATIVE_FILTER-project,"
        f"filterState:(value:!('{val}')),"
        f"extraFormData:(filters:!((col:project_name,op:IN,val:!('{val}'))))"
        "))"
    )
    encoded_filter = urllib.parse.quote(rison_filter, safe="")

    embed_url = (
        f"{superset_base}/superset/dashboard/assessments/?standalone=2"
        if superset_base else ""
    )

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "user": current_user(request),
            "slug": "assessments",
            "dashboard": {
                "title": f"Project: {name}",
                "description": f"Assessments for software in project {name}.",
                "audience": "Per-project view",
                "rsqkit_url": "",
                "hide_filters": True,
            },
            "embed_url": embed_url,
            "encoded_software_filter": encoded_filter,
            "native_filters_key": permalink_key,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": "assessments",
        }
    )


async def _home_stats(user: dict | None) -> dict:
    headers = {"Accept": "application/json"}
    if user and user.get("token"):
        headers["Authorization"] = f"Bearer {user['token']}"
    try:
        async with httpx.AsyncClient(timeout=3) as client:
            r = await client.get(
                f"{settings.backend_url.rstrip('/')}/api/stats/home",
                headers=headers,
            )
        if r.status_code == 200:
            return r.json()
    except httpx.RequestError as exc:
        log.warning("home stats fetch failed: %s", exc)
    return {}


@router.get("/", response_class=HTMLResponse)
async def home(
    request: Request,
    software: str | None = Query(default=None),
    project: str | None = Query(default=None),
):
    if software:
        return _software_detail_response(request, software)
    if project:
        return _project_detail_response(request, project)
    user = current_user(request)
    stats = await _home_stats(user)
    return templates.TemplateResponse(
        "home.html",
        {
            "request": request,
            "user": user,
            "stats": stats,
            "dashboards": DASHBOARDS,
            "superset_url": settings.superset_url,
            "api_docs_url": settings.api_docs_external_url,
            "current_dashboard": None,
        }
    )


@router.get("/software/{name}", response_class=HTMLResponse)
async def software_detail(request: Request, name: str):
    return _software_detail_response(request, name)


@router.get("/project/{name}", response_class=HTMLResponse)
async def project_detail(request: Request, name: str):
    return _project_detail_response(request, name)


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
            "user": current_user(request),
            "dashboards": DASHBOARDS,
            "current_dashboard": None,
            "assessment_example": assessment_example_json,
        },
    )


@router.get("/dashboard/{slug}", response_class=HTMLResponse)
async def dashboard(
    request: Request,
    slug: str,
    software: str | None = Query(default=None),
    project: str | None = Query(default=None),
):
    if slug not in DASHBOARDS:
        raise HTTPException(status_code=404, detail="Dashboard not found")

    if slug == "assessments":
        if software:
            return _software_detail_response(request, software)
        if project:
            return _project_detail_response(request, project)

    dashboard_info = DASHBOARDS[slug]
    user = current_user(request)
    if dashboard_info.get("auth_required") and not user:
        return RedirectResponse(
            url=f"/login?next={urllib.parse.quote('/dashboard/' + slug, safe='')}",
            status_code=302,
        )

    superset_base = settings.superset_external_url or ""
    embed_url = f"{superset_base}/superset/dashboard/{slug}/?standalone=2" if superset_base else ""

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "user": user,
            "slug": slug,
            "dashboard": dashboard_info,
            "embed_url": embed_url,
            "embedded_uuid": _embedded_dashboard_uuid(slug),
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": slug,
        }
    )


@router.post("/superset/refresh")
async def superset_refresh(request: Request):
    _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return {"invalidated": len(_PROJECT_AWARE_DATASET_UUIDS)}


@router.post("/superset/guest-token/{slug}")
async def superset_guest_token(request: Request, slug: str):
    if slug not in DASHBOARDS:
        raise HTTPException(status_code=404, detail="Unknown dashboard")
    token = _superset_guest_token_for(slug, current_user(request))
    if not token:
        raise HTTPException(status_code=502, detail="Could not mint guest token")
    return {"token": token}


def _safe_next(value: str | None) -> str:
    if not value or not value.startswith("/") or value.startswith("//"):
        return "/"
    return value


@router.get("/login", response_class=HTMLResponse)
async def login_page(
    request: Request,
    next: str | None = Query(default="/"),
    stale: str | None = Query(default=None),
):
    if current_user(request):
        return RedirectResponse(url=_safe_next(next), status_code=302)
    return templates.TemplateResponse(
        "login.html",
        {
            "request": request,
            "user": None,
            "dashboards": DASHBOARDS,
            "current_dashboard": None,
            "next": _safe_next(next),
            "error": "Your session has expired. Please sign in again." if stale else None,
        },
    )


@router.post("/login", response_class=HTMLResponse)
async def login_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    next: str = Form(default="/"),
):
    body, error = _auth_post("/api/auth/login", {
        "username": username,
        "password": password,
    })
    access_token = (body or {}).get("access_token") if body else None
    if not access_token:
        return templates.TemplateResponse(
            "login.html",
            {
                "request": request,
                "user": None,
                "dashboards": DASHBOARDS,
                "current_dashboard": None,
                "next": _safe_next(next),
                "error": error or "Incorrect username or password",
            },
            status_code=401,
        )
    return _issue_session_cookie(access_token, next)


def _issue_session_cookie(access_token: str, next_url: str) -> RedirectResponse:
    response = RedirectResponse(url=_safe_next(next_url), status_code=302)
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        samesite="lax",
        max_age=14 * 24 * 60 * 60,
    )
    return response


def _auth_post(path: str, payload: dict) -> tuple[dict | None, str | None]:
    req = urllib.request.Request(
        f"{settings.backend_url.rstrip('/')}{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read()), None
    except urllib.error.HTTPError as exc:
        try:
            body = json.loads(exc.read())
            return None, body.get("detail") or f"Request failed ({exc.code})"
        except Exception:
            return None, f"Request failed ({exc.code})"
    except Exception as exc:
        log.warning("backend %s failed: %s", path, exc)
        return None, "Authentication service unavailable. Please try again later."


@router.get("/register", response_class=HTMLResponse)
async def register_page(request: Request):
    if current_user(request):
        return RedirectResponse(url="/", status_code=302)
    return templates.TemplateResponse(
        "register.html",
        {
            "request": request,
            "user": None,
            "dashboards": DASHBOARDS,
            "current_dashboard": None,
            "password_min_length": settings.password_min_length,
        },
    )


@router.post("/register", response_class=HTMLResponse)
async def register_submit(
    request: Request,
    username: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
):
    def _form_with_error(message: str, code: int = 400):
        return templates.TemplateResponse(
            "register.html",
            {
                "request": request,
                "user": None,
                "dashboards": DASHBOARDS,
                "current_dashboard": None,
                "password_min_length": settings.password_min_length,
                "error": message,
                "username": username,
                "email": email,
            },
            status_code=code,
        )

    if len(password) < settings.password_min_length:
        return _form_with_error(
            f"Password must be at least {settings.password_min_length} characters."
        )

    _, error = _auth_post("/api/auth/register", {
        "username": username,
        "email": email,
        "password": password,
    })
    if error:
        return _form_with_error(error, code=409 if "already" in error.lower() else 400)

    body, login_error = _auth_post("/api/auth/login", {
        "username": username,
        "password": password,
    })
    access_token = (body or {}).get("access_token") if body else None
    if not access_token:
        return RedirectResponse(
            url=f"/login?next=/&registered={urllib.parse.quote(username, safe='')}",
            status_code=302,
        )
    return _issue_session_cookie(access_token, "/")


@router.get("/logout")
async def logout(request: Request):
    response = RedirectResponse(url="/", status_code=302)
    response.delete_cookie("access_token")
    return response


def _auth_request(method: str, path: str, token: str, payload: dict | None = None) -> tuple[dict | list | None, str | None, int]:
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        f"{settings.backend_url.rstrip('/')}{path}",
        data=data,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {token}",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read()
            return (json.loads(body) if body else {}), None, resp.status
    except urllib.error.HTTPError as exc:
        try:
            body = json.loads(exc.read())
            return None, body.get("detail") or f"Request failed ({exc.code})", exc.code
        except Exception:
            return None, f"Request failed ({exc.code})", exc.code
    except Exception as exc:
        log.warning("backend %s %s failed: %s", method, path, exc)
        return None, "Authentication service unavailable. Please try again later.", 0


def _stale_session_redirect(next_path: str) -> RedirectResponse:
    response = RedirectResponse(
        url=f"/login?next={urllib.parse.quote(next_path, safe='')}&stale=1",
        status_code=302,
    )
    response.delete_cookie("access_token")
    return response


async def _auth_get_async(client: httpx.AsyncClient, path: str, token: str) -> tuple[dict | list | None, str | None, int]:
    try:
        resp = await client.get(
            f"{settings.backend_url.rstrip('/')}{path}",
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/json",
            },
            timeout=5,
        )
    except httpx.RequestError as exc:
        log.warning("backend GET %s failed: %s", path, exc)
        return None, "Authentication service unavailable. Please try again later.", 0
    if resp.status_code >= 400:
        try:
            body = resp.json()
            return None, body.get("detail") or f"Request failed ({resp.status_code})", resp.status_code
        except Exception:
            return None, f"Request failed ({resp.status_code})", resp.status_code
    try:
        return resp.json(), None, resp.status_code
    except Exception:
        return {}, None, resp.status_code


def _account_redirect(error: str | None = None) -> RedirectResponse:
    if error:
        return RedirectResponse(
            url=f"/account?error={urllib.parse.quote(error)}",
            status_code=303,
        )
    return RedirectResponse(url="/account", status_code=303)


async def _account_context(request: Request, user: dict, *, new_token: str | None = None, error: str | None = None):
    token = user["token"]
    async with httpx.AsyncClient() as client:
        tokens_r, projects_r, software_r, me_r = await asyncio.gather(
            _auth_get_async(client, "/api/tokens/", token),
            _auth_get_async(client, "/api/projects/", token),
            _auth_get_async(client, "/api/projects/me/software", token),
            _auth_get_async(client, "/api/auth/me", token),
        )
    tokens_body, list_error, status = tokens_r
    tokens = (tokens_body or {}).get("tokens", []) if isinstance(tokens_body, dict) else []
    projects_body, _, _ = projects_r
    projects = (projects_body or {}).get("projects", []) if isinstance(projects_body, dict) else []
    software_body, _, _ = software_r
    software = (software_body or {}).get("software", []) if isinstance(software_body, dict) else []
    me_body, _, _ = me_r
    profile = me_body if isinstance(me_body, dict) else {}
    stats = await _home_stats(user)
    return {
        "request": request,
        "user": user,
        "profile": profile,
        "dashboards": DASHBOARDS,
        "current_dashboard": None,
        "tokens": tokens,
        "new_token": new_token,
        "error": error or list_error,
        "list_status": status,
        "projects": projects,
        "software": software,
        "stats": stats,
        "dashverse_api_url": settings.postgrest_external_url,
    }


@router.get("/account", response_class=HTMLResponse)
async def account_page(request: Request, error: str | None = None):
    user = current_user(request)
    if not user:
        return RedirectResponse(
            url=f"/login?next={urllib.parse.quote('/account', safe='')}",
            status_code=302,
        )
    new_token = request.cookies.get("dv_new_token")
    ctx = await _account_context(request, user, new_token=new_token, error=error)
    if ctx["list_status"] == 401:
        return _stale_session_redirect("/account")
    resp = templates.TemplateResponse("account.html", ctx)
    if new_token:
        resp.delete_cookie("dv_new_token", path="/account")
    return resp


@router.post("/account/tokens", response_class=HTMLResponse)
async def account_token_create(
    request: Request,
    token_name: str = Form(default=""),
    project_id: str = Form(default=""),
    ttl_days: str = Form(default=""),
):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    payload: dict = {"token_name": token_name.strip() or None}
    if project_id.strip():
        try:
            payload["project_id"] = int(project_id)
        except ValueError:
            pass
    if ttl_days.strip():
        try:
            payload["ttl_days"] = int(ttl_days)
        except ValueError:
            pass
    body, error, status = _auth_request("POST", "/api/tokens/", user["token"], payload)
    if status == 401:
        return _stale_session_redirect("/account")
    new_jwt = (body or {}).get("access_token") if isinstance(body, dict) else None
    resp = _account_redirect(error=error)
    if new_jwt:
        resp.set_cookie(
            "dv_new_token",
            new_jwt,
            max_age=60,
            httponly=True,
            samesite="lax",
            path="/account",
        )
    return resp


@router.post("/account/tokens/{token_id}/revoke", response_class=HTMLResponse)
def account_token_revoke(request: Request, token_id: int):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request("POST", "/api/tokens/revoke", user["token"], {"token_id": token_id})
    if status == 401:
        return _stale_session_redirect("/account")
    return _account_redirect(error=error)


@router.post("/account/tokens/{token_id}/delete", response_class=HTMLResponse)
async def account_token_delete(request: Request, token_id: int):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request("DELETE", f"/api/tokens/{token_id}", user["token"])
    if status == 401:
        return _stale_session_redirect("/account")
    return _account_redirect(error=error)


@router.post("/account/software/assign", response_class=HTMLResponse)
def account_software_assign(
    request: Request,
    software_name: str = Form(...),
    project_id: int = Form(...),
):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request(
        "POST",
        f"/api/projects/{project_id}/software",
        user["token"],
        {"software_name": software_name},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    return _account_redirect(error=error)


@router.post("/account/software/delete", response_class=HTMLResponse)
async def account_software_delete(
    request: Request,
    software_name: str = Form(...),
):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request(
        "POST",
        "/api/projects/me/software/delete",
        user["token"],
        {"software_name": software_name},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


@router.post("/account/software/visibility", response_class=HTMLResponse)
async def account_software_visibility(
    request: Request,
    software_name: str = Form(...),
    visibility: str = Form(...),
):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)

    if visibility in ("private", "authenticated", "public"):
        vis_payload: str | None = visibility
    elif visibility == "clear":
        vis_payload = None
    else:
        return _account_redirect(error="Unknown visibility value.")

    _, error, status = _auth_request(
        "PUT",
        "/api/projects/me/software/visibility",
        user["token"],
        {"software_name": software_name, "visibility": vis_payload},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


@router.post("/account/projects", response_class=HTMLResponse)
def account_project_create(
    request: Request,
    name: str = Form(...),
    visibility: str = Form(default="public"),
):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    name = name.strip()
    if not name:
        return _account_redirect(error="Project name is required.")
    if visibility not in ("private", "authenticated", "public"):
        visibility = "public"
    _, error, status = _auth_request(
        "POST",
        "/api/projects/",
        user["token"],
        {"name": name, "visibility": visibility},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


@router.post("/account/projects/{project_id}/visibility", response_class=HTMLResponse)
async def account_project_visibility(request: Request, project_id: int, visibility: str = Form(...)):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    if visibility not in ("private", "authenticated", "public"):
        return _account_redirect(error="Unknown visibility value.")
    _, error, status = _auth_request(
        "PATCH",
        f"/api/projects/{project_id}",
        user["token"],
        {"visibility": visibility},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


@router.post("/account/projects/{project_id}/rename", response_class=HTMLResponse)
async def account_project_rename(request: Request, project_id: int, name: str = Form(...)):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    name = name.strip()
    if not name:
        return _account_redirect(error="Project name is required.")
    _, error, status = _auth_request(
        "PATCH",
        f"/api/projects/{project_id}",
        user["token"],
        {"name": name},
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


@router.post("/account/projects/{project_id}/delete", response_class=HTMLResponse)
def account_project_delete(request: Request, project_id: int):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request(
        "DELETE",
        f"/api/projects/{project_id}",
        user["token"],
    )
    if status == 401:
        return _stale_session_redirect("/account")
    if not error:
        _superset_invalidate_datasets(_PROJECT_AWARE_DATASET_UUIDS)
    return _account_redirect(error=error)


