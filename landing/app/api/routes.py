from fastapi import APIRouter, Request, HTTPException, Query, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
import os
import json
import time
import logging
import urllib.parse
import urllib.request
import urllib.error

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

templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

DASHBOARDS = {
    "global": {
        "title": "Global Overview",
        "description": "Portfolio-wide quality assessment activity plus the EVERSE quality model catalog. Aggregate counts and rates; no software or project names are exposed.",
        "audience": "Open to anonymous visitors. No login required.",
        "rsqkit_url": "",
    },
    "assessments": {
        "title": "Assessments Explorer",
        "description": "Filter-driven view of every assessment you can see. Per-software KPIs, trend, dimension radar, vs-median, compliance heatmap, improvement targets, failed checks, recent activity, and checking-tool usage.",
        "audience": "Anyone. The view narrows automatically to the scope you're allowed to see.",
        "rsqkit_url": "",
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


@router.get("/", response_class=HTMLResponse)
async def home(request: Request, software: str | None = Query(default=None)):
    if software:
        return _software_detail_response(request, software)
    return templates.TemplateResponse(
        "home.html",
        {
            "request": request,
            "user": current_user(request),
            "dashboards": DASHBOARDS,
            "superset_url": settings.superset_url,
            "current_dashboard": None,
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
            "user": current_user(request),
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
            "user": current_user(request),
            "slug": slug,
            "dashboard": dashboard_info,
            "embed_url": embed_url,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": slug,
        }
    )


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
        f"{settings.auth_service_url.rstrip('/')}{path}",
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
        log.warning("auth-service %s failed: %s", path, exc)
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
        f"{settings.auth_service_url.rstrip('/')}{path}",
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
        log.warning("auth-service %s %s failed: %s", method, path, exc)
        return None, "Authentication service unavailable. Please try again later.", 0


def _stale_session_redirect(next_path: str) -> RedirectResponse:
    response = RedirectResponse(
        url=f"/login?next={urllib.parse.quote(next_path, safe='')}&stale=1",
        status_code=302,
    )
    response.delete_cookie("access_token")
    return response


def _account_context(request: Request, user: dict, *, new_token: str | None = None, error: str | None = None):
    body, list_error, status = _auth_request("GET", "/api/tokens/", user["token"])
    tokens = (body or {}).get("tokens", []) if isinstance(body, dict) else []
    return {
        "request": request,
        "user": user,
        "dashboards": DASHBOARDS,
        "current_dashboard": None,
        "tokens": tokens,
        "new_token": new_token,
        "error": error or list_error,
        "list_status": status,
    }


@router.get("/account", response_class=HTMLResponse)
async def account_page(request: Request):
    user = current_user(request)
    if not user:
        return RedirectResponse(
            url=f"/login?next={urllib.parse.quote('/account', safe='')}",
            status_code=302,
        )
    ctx = _account_context(request, user)
    if ctx["list_status"] == 401:
        return _stale_session_redirect("/account")
    return templates.TemplateResponse("account.html", ctx)


@router.post("/account/tokens", response_class=HTMLResponse)
async def account_token_create(request: Request, token_name: str = Form(default="")):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    payload = {"token_name": token_name.strip() or None}
    body, error, status = _auth_request("POST", "/api/tokens/", user["token"], payload)
    if status == 401:
        return _stale_session_redirect("/account")
    new_jwt = (body or {}).get("access_token") if isinstance(body, dict) else None
    return templates.TemplateResponse(
        "account.html",
        _account_context(request, user, new_token=new_jwt, error=error),
        status_code=201 if new_jwt else 400,
    )


@router.post("/account/tokens/{token_id}/revoke", response_class=HTMLResponse)
async def account_token_revoke(request: Request, token_id: int):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request("POST", "/api/tokens/revoke", user["token"], {"token_id": token_id})
    if status == 401:
        return _stale_session_redirect("/account")
    return templates.TemplateResponse(
        "account.html",
        _account_context(request, user, error=error),
    )


@router.post("/account/tokens/{token_id}/delete", response_class=HTMLResponse)
async def account_token_delete(request: Request, token_id: int):
    user = current_user(request)
    if not user:
        return RedirectResponse(url="/login?next=/account", status_code=302)
    _, error, status = _auth_request("DELETE", f"/api/tokens/{token_id}", user["token"])
    if status == 401:
        return _stale_session_redirect("/account")
    return templates.TemplateResponse(
        "account.html",
        _account_context(request, user, error=error),
    )


def _my_software_names(sub: str, token: str) -> list[str]:
    if not settings.postgrest_url or not sub:
        return []
    qs = urllib.parse.urlencode({
        "created_by": f"eq.{sub}",
        "select": "name:payload->assessedSoftware->>name",
    })
    url = f"{settings.postgrest_url}/assessment_raw?{qs}"
    try:
        req = urllib.request.Request(url, headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        })
        with urllib.request.urlopen(req, timeout=5) as resp:
            rows = json.loads(resp.read())
    except Exception as exc:
        log.warning("PostgREST /assessment_raw lookup failed: %s", exc)
        return []
    seen: list[str] = []
    for row in rows:
        name = row.get("name")
        if name and name not in seen:
            seen.append(name)
    return seen


@router.get("/me/assessments", response_class=HTMLResponse)
async def my_assessments(request: Request):
    user = current_user(request)
    if not user:
        return RedirectResponse(
            url=f"/login?next={urllib.parse.quote('/me/assessments', safe='')}",
            status_code=302,
        )

    names = _my_software_names(user["sub"], user["token"])
    superset_base = settings.superset_external_url or ""

    permalink_key = None
    encoded_filter = ""
    if names:
        filter_state = {
            "NATIVE_FILTER-software": {
                "id": "NATIVE_FILTER-software",
                "extraFormData": {
                    "filters": [{"col": "software_name", "op": "IN", "val": names}]
                },
                "filterState": {"value": names},
            }
        }
        permalink_key = _filter_state_key("assessments", filter_state)

        val_list = ",".join(f"'{n.replace(chr(39), chr(92) + chr(39))}'" for n in names)
        rison_filter = (
            "(NATIVE_FILTER-software:("
            "id:NATIVE_FILTER-software,"
            f"filterState:(value:!({val_list})),"
            f"extraFormData:(filters:!((col:software_name,op:IN,val:!({val_list}))))"
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
            "user": user,
            "slug": "assessments",
            "dashboard": {
                "title": "My Assessments",
                "description": (
                    f"Assessments Explorer scoped to {len(names)} software(s) you've assessed."
                    if names else
                    "You have not authored any assessments yet. Showing the unscoped view."
                ),
                "audience": user.get("username") or "you",
                "rsqkit_url": "",
            },
            "embed_url": embed_url,
            "encoded_software_filter": encoded_filter,
            "native_filters_key": permalink_key,
            "superset_external_url": superset_base,
            "dashboards": DASHBOARDS,
            "current_dashboard": "assessments",
        }
    )
