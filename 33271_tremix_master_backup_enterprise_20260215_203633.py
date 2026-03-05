
# ---- Localhost-only dashboard protection ----
def enforce_localhost(request: Request):
    try:
        ip = (request.client.host or "").strip()
    except Exception:
        ip = ""
    if ip not in ("127.0.0.1", "::1"):
        raise PermissionError("dashboard_localhost_only")

#!/usr/bin/env python3
import os, sys, json, time, signal, subprocess, secrets, hashlib, re
from datetime import datetime
from typing import Optional, Dict, Any, List, Tuple

from fastapi import FastAPI, Form, Request, Header, UploadFile, File
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
import uvicorn

# Optional parsers
try:
    from pypdf import PdfReader  # type: ignore
except Exception:
    PdfReader = None
try:
    import docx  # type: ignore
except Exception:
    docx = None

# ---------------- CONFIG ----------------
BASE_DIR = os.path.expanduser("~/Tremix")
PROJECTS_DIR = os.path.join(BASE_DIR, "projects")
REGISTRY_FILE = os.path.join(BASE_DIR, "registry.json")
LOG_FILE = os.path.join(BASE_DIR, "tremix.log")

TASK_FILE = os.path.join(BASE_DIR, "tasks.json")
MEMORY_FILE = os.path.join(BASE_DIR, "memory.json")
OUTBOX_DIR = os.path.join(BASE_DIR, "outbox")
INBOX_DIR = os.path.join(BASE_DIR, "inbox")

USERS_FILE = os.path.join(BASE_DIR, "users.json")
SESSIONS_FILE = os.path.join(BASE_DIR, "sessions.json")
TOKENS_FILE = os.path.join(BASE_DIR, "tokens.json")
AUDIT_FILE = os.path.join(BASE_DIR, "audit.log")

WORKER_PID_FILE = os.path.join(BASE_DIR, "task_worker.pid")

DEFAULT_HOST = "127.0.0.1"
BASE_PORT = 8000
DASHBOARD_PORT = 8080

# AI backend (optional)
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "").strip()
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434").strip()
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1").strip()

# Rate limit for token API
RL_WINDOW_SEC = 10
RL_MAX_REQ = 25
_rate_bucket: Dict[str, List[float]] = {}

# ---------------- utils ----------------
def ensure_dirs():
    os.makedirs(BASE_DIR, exist_ok=True)
    os.makedirs(PROJECTS_DIR, exist_ok=True)
    os.makedirs(OUTBOX_DIR, exist_ok=True)
    os.makedirs(INBOX_DIR, exist_ok=True)

    def init(path, default):
        if not os.path.exists(path):
            save_json(path, default)

    init(REGISTRY_FILE, {})
    init(TASK_FILE, [])
    init(MEMORY_FILE, [])
    init(SESSIONS_FILE, {})
    init(TOKENS_FILE, {})

    if not os.path.exists(USERS_FILE):
        users = {"admin": {"role": "admin", "pass_sha256": sha256("admin123")}}
        save_json(USERS_FILE, users)
        log("Created default admin (admin/admin123). Change ASAP.")
        audit("system", "bootstrap_default_admin", {"user": "admin"})

def log(msg: str):
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().isoformat()}] {msg}\n")

def audit(actor: str, action: str, meta: Dict[str, Any]):
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(AUDIT_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps({
            "ts": datetime.now().isoformat(),
            "actor": actor, "action": action, "meta": meta
        }, ensure_ascii=False) + "\n")

def load_json(path: str, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default

def save_json(path: str, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def tail(path: str, n: int = 200) -> str:
    if not os.path.exists(path): return ""
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    return "".join(lines[-n:])

def is_pid_alive(pid: int) -> bool:
    try: os.kill(pid, 0); return True
    except Exception: return False

def sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()

# ---------------- auth (users/sessions) ----------------
def load_users(): return load_json(USERS_FILE, {})
def save_users(u): save_json(USERS_FILE, u)
def load_sessions(): return load_json(SESSIONS_FILE, {})
def save_sessions(s): save_json(SESSIONS_FILE, s)

def create_session(username: str) -> str:
    sessions = load_sessions()
    token = secrets.token_urlsafe(32)
    sessions[token] = {"user": username, "created_at": datetime.now().isoformat()}
    save_sessions(sessions)
    return token

def destroy_session(token: str):
    sessions = load_sessions()
    if token in sessions:
        sessions.pop(token); save_sessions(sessions)

def get_current_user(request: Request) -> Optional[Dict[str, Any]]:
    token = request.cookies.get("tremix_session", "")
    if not token:
        return None
    if not is_session_valid(token):
        return None
    sessions = load_sessions()
    s = sessions.get(token)
    if not s:
        return None
    users = load_users()
    u = users.get(s["user"])
    if not u:
        return None
    return {"username": s["user"], "role": u.get("role", "viewer"), "session_token": token}
