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
    tok = request.cookies.get("tremix_session", "")
    if not tok: return None
    s = load_sessions().get(tok)
    if not s: return None
    u = load_users().get(s["user"])
    if not u: return None
    return {"username": s["user"], "role": u.get("role","viewer"), "session_token": tok}

def require_login(request: Request) -> Dict[str, Any]:
    u = get_current_user(request)
    if not u: raise PermissionError("login_required")
    return u

def require_role(user: Dict[str, Any], allowed: List[str]):
    if user.get("role") not in allowed:
        raise PermissionError("forbidden")

# ---------------- API tokens ----------------
def load_tokens(): return load_json(TOKENS_FILE, {})
def save_tokens(t): save_json(TOKENS_FILE, t)

def create_api_token(username: str, label: str = "") -> str:
    tokens = load_tokens()
    token = secrets.token_urlsafe(36)
    tokens[token] = {"user": username, "label": label, "created_at": datetime.now().isoformat(), "revoked": False}
    save_tokens(tokens)
    return token

def revoke_api_token(token: str):
    tokens = load_tokens()
    if token in tokens:
        tokens[token]["revoked"] = True
        tokens[token]["revoked_at"] = datetime.now().isoformat()
        save_tokens(tokens)

def auth_api_token(x_api_token: Optional[str]) -> Optional[Dict[str, Any]]:
    if not x_api_token: return None
    tokens = load_tokens()
    t = tokens.get(x_api_token)
    if not t or t.get("revoked"): return None
    u = load_users().get(t["user"])
    if not u: return None
    return {"username": t["user"], "role": u.get("role","viewer"), "token": x_api_token, "label": t.get("label","")}

def rate_limit_or_429(token: str) -> Optional[JSONResponse]:
    now = time.time()
    bucket = _rate_bucket.setdefault(token, [])
    bucket[:] = [ts for ts in bucket if now - ts <= RL_WINDOW_SEC]
    if len(bucket) >= RL_MAX_REQ:
        return JSONResponse({"ok": False, "error": "rate_limited", "window_sec": RL_WINDOW_SEC, "max_req": RL_MAX_REQ}, status_code=429)
    bucket.append(now)
    return None

def require_api(x_api_token: Optional[str]) -> Tuple[Dict[str, Any], Optional[JSONResponse]]:
    au = auth_api_token(x_api_token)
    if not au:
        return {}, JSONResponse({"ok": False, "error": "unauthorized"}, status_code=401)
    rl = rate_limit_or_429(au["token"])
    if rl: return au, rl
    return au, None

# ---------------- services ----------------
def load_registry(): return load_json(REGISTRY_FILE, {})
def save_registry(r): save_json(REGISTRY_FILE, r)
def project_path(name: str) -> str: return os.path.join(PROJECTS_DIR, name)

def allocate_port(reg: Dict[str, Any]) -> int:
    used=set()
    for _,info in reg.items():
        p=info.get("port")
        if p:
            try: used.add(int(p))
            except: pass
    for port in range(BASE_PORT, BASE_PORT+200):
        if port not in used: return port
    raise RuntimeError("No free ports")

def create_service(name: str):
    ensure_dirs()
    path = project_path(name)
    os.makedirs(path, exist_ok=True)
    main_py = f'''from fastapi import FastAPI
app = FastAPI()
@app.get("/")
def root():
    return {{"service": "{name}", "status":"running"}}
'''
    with open(os.path.join(path,"main.py"),"w",encoding="utf-8") as f: f.write(main_py)
    with open(os.path.join(path,"requirements.txt"),"w",encoding="utf-8") as f: f.write("fastapi\nuvicorn\n")

    reg = load_registry()
    reg.setdefault(name,{})
    reg[name].update({"status":"created","created_at":datetime.now().isoformat(),"path":path})
    save_registry(reg)
    log(f"Created service {name}")

def setup_service(name: str):
    path = project_path(name)
    venv = os.path.join(path,".venv")
    if not os.path.exists(os.path.join(venv,"bin","python")):
        subprocess.run([sys.executable,"-m","venv",venv], cwd=path, check=True)
    pip = os.path.join(venv,"bin","pip")
    subprocess.run([pip,"install","--upgrade","pip"], cwd=path, check=True)
    subprocess.run([pip,"install","-r","requirements.txt"], cwd=path, check=True)

def start_service(name: str, port: Optional[int]=None):
    reg = load_registry()
    if name not in reg:
        create_service(name); reg = load_registry()

    info = reg.get(name,{})
    if info.get("status")=="running" and info.get("pid"):
        try:
            if is_pid_alive(int(info["pid"])): return
        except: pass

    path = project_path(name)
    uvicorn_bin = os.path.join(path,".venv","bin","uvicorn")
    if not os.path.exists(uvicorn_bin): setup_service(name)
    if port is None: port = allocate_port(reg)

    svc_log = os.path.join(BASE_DIR, f"{name}.log")
    with open(svc_log,"a",encoding="utf-8") as out:
        proc = subprocess.Popen([uvicorn_bin,"main:app","--host",DEFAULT_HOST,"--port",str(port),"--reload"],
                                cwd=path, stdout=out, stderr=out)
    reg[name].update({"status":"running","pid":proc.pid,"host":DEFAULT_HOST,"port":int(port),"svc_log":svc_log,"started_at":datetime.now().isoformat()})
    save_registry(reg)

def stop_service(name: str):
    reg = load_registry()
    info = reg.get(name)
    if not info: return
    pid = info.get("pid")
    try: pid = int(pid) if pid else None
    except: pid=None
    if pid and is_pid_alive(pid):
        try:
            os.kill(pid, signal.SIGTERM); time.sleep(0.6)
            if is_pid_alive(pid): os.kill(pid, signal.SIGKILL)
        except: pass
    reg[name]["status"]="stopped"; save_registry(reg)

def restart_service(name: str):
    stop_service(name); time.sleep(0.3); start_service(name)

# ---------------- tasks + memory ----------------
def add_memory(entry_type: str, content: Any):
    mem = load_json(MEMORY_FILE, [])
    mem.append({"type": entry_type, "content": content, "ts": datetime.now().isoformat()})
    save_json(MEMORY_FILE, mem)

def load_tasks(): return load_json(TASK_FILE, [])
def save_tasks(t): save_json(TASK_FILE, t)

def add_task(data: str) -> int:
    tasks = load_tasks()
    nid = 1
    if tasks:
        try: nid = max(int(x.get("id",0)) for x in tasks) + 1
        except: nid = len(tasks)+1
    tasks.append({"id": nid, "status":"pending", "data": data, "created_at": datetime.now().isoformat()})
    save_tasks(tasks)
    return nid

def doctor_pipeline_heuristic(text: str) -> Dict[str, Any]:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    issues = [ln for ln in lines if any(k in ln.lower() for k in ["traceback","error","exception","failed"])]
    actions = [ln for ln in lines if any(k in ln.lower() for k in ["todo","fixme","fix","urgent","مطلوب","لازم","ضروري"])]
    return {
        "summary": (text[:320] + ("..." if len(text)>320 else "")),
        "key_points": lines[:12],
        "issues": issues[:12],
        "actions": actions[:12]
    }

def ai_analyze(text: str, instruction: str="") -> Dict[str, Any]:
    # 1) Ollama
    prompt = f"""أنت فريق دكاترة داخل Tremix.
حلّل النص التالي وقدّم:
- Summary واضح
- Key points
- Issues/Errors
- Actions
- Next steps
Instruction: {instruction}

TEXT:
{text[:120000]}
"""
    # Try Ollama
    if OLLAMA_HOST:
        try:
            import urllib.request
            url = OLLAMA_HOST.rstrip("/") + "/api/generate"
            payload = json.dumps({"model": OLLAMA_MODEL, "prompt": prompt, "stream": False}).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={"Content-Type":"application/json"})
            with urllib.request.urlopen(req, timeout=25) as resp:
                data = json.loads(resp.read().decode("utf-8", errors="ignore"))
            out = (data.get("response") or "").strip()
            if out:
                return {"backend":"ollama","raw":out}
        except Exception:
            pass

    # Try OpenAI (best-effort)
    if OPENAI_API_KEY:
        try:
            import urllib.request
            url = "https://api.openai.com/v1/responses"
            payload = {"model":"gpt-4.1-mini","input":prompt}
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type":"application/json","Authorization":f"Bearer {OPENAI_API_KEY}"}
            )
            with urllib.request.urlopen(req, timeout=25) as resp:
                data = json.loads(resp.read().decode("utf-8", errors="ignore"))
            out = (data.get("output_text") or "").strip()
            if not out:
                # best-effort parse
                for item in (data.get("output") or []):
                    for c in (item.get("content") or []):
                        if c.get("type") == "output_text":
                            out += c.get("text","")
                out = out.strip()
            if out:
                return {"backend":"openai","raw":out}
        except Exception:
            pass

    return {"backend":"heuristic","structured": doctor_pipeline_heuristic(text)}

def worker_tick():
    tasks = load_tasks()
    changed = False
    for task in tasks:
        if task.get("status") == "pending":
            task["status"] = "running"
            task["started_at"] = datetime.now().isoformat()
            save_tasks(tasks)
            try:
                result = doctor_pipeline_heuristic(task.get("data",""))
                out_path = os.path.join(OUTBOX_DIR, f"task_{task.get('id')}.json")
                save_json(out_path, {"task_id": task.get("id"), **result, "processed_at": datetime.now().isoformat()})
                add_memory("task_result", {"task_id": task.get("id"), **result})
                task["status"] = "done"
                task["done_at"] = datetime.now().isoformat()
            except Exception as e:
                task["status"] = "failed"
                task["error"] = str(e)
                task["failed_at"] = datetime.now().isoformat()
            changed = True
    if changed:
        save_tasks(tasks)

def worker_loop():
    log("Task worker started (foreground)")
    while True:
        worker_tick()
        time.sleep(3)

def worker_status():
    if not os.path.exists(WORKER_PID_FILE): return {"running": False}
    try: pid = int(open(WORKER_PID_FILE,"r").read().strip())
    except: return {"running": False}
    return {"running": is_pid_alive(pid), "pid": pid}

def worker_start_bg():
    st = worker_status()
    if st.get("running"): return st
    proc = subprocess.Popen([sys.executable, os.path.abspath(__file__), "worker"])
    with open(WORKER_PID_FILE,"w") as f: f.write(str(proc.pid))
    return {"running": True, "pid": proc.pid}

def worker_stop_bg():
    st = worker_status()
    pid = st.get("pid")
    if not pid: return {"running": False}
    try:
        os.kill(pid, signal.SIGTERM); time.sleep(0.5)
        if is_pid_alive(pid): os.kill(pid, signal.SIGKILL)
    except: pass
    try: os.remove(WORKER_PID_FILE)
    except: pass
    return {"running": False}

# ---------------- file extraction ----------------
def extract_text(path: str, limit_chars: int=120000) -> str:
    ext = os.path.splitext(path)[1].lower()

    if ext in [".txt",".log",".md",".py",".json",".csv",".yaml",".yml"]:
        with open(path,"r",encoding="utf-8",errors="ignore") as f:
            return f.read()[:limit_chars]

    if ext == ".pdf":
        if PdfReader is None:
            return "PDF support missing. Install: pip install pypdf"
        try:
            r = PdfReader(path)
            parts=[]
            for p in r.pages[:50]:
                parts.append(p.extract_text() or "")
            return ("\n".join(parts))[:limit_chars]
        except Exception as e:
            return f"PDF extract error: {e}"

    if ext == ".docx":
        if docx is None:
            return "DOCX support missing. Install: pip install python-docx"
        try:
            d = docx.Document(path)
            return ("\n".join([p.text for p in d.paragraphs]))[:limit_chars]
        except Exception as e:
            return f"DOCX extract error: {e}"

    # fallback: try as text
    try:
        with open(path,"r",encoding="utf-8",errors="ignore") as f:
            return f.read()[:limit_chars]
    except Exception:
        return f"Unsupported file type: {ext}"

# ---------------- app ----------------
app = FastAPI()

def forbid_page(msg="Forbidden") -> HTMLResponse:
    return HTMLResponse(f"<h2>⛔ {msg}</h2><p><a href='/'>Back</a></p>", status_code=403)

def login_page(error: str="") -> HTMLResponse:
    msg = f"<p style='color:red'>{error}</p>" if error else ""
    return HTMLResponse(f"""
    <html><head><meta charset="utf-8"/><title>Login</title></head>
    <body style="font-family:sans-serif;padding:18px">
    <h1>🔐 Tremix Login</h1>
    {msg}
    <form method="post" action="/login">
      <input name="username" placeholder="username" required /><br/><br/>
      <input name="password" placeholder="password" type="password" required /><br/><br/>
      <button type="submit">Login</button>
    </form>
    <p>Default admin: <code>admin</code> / <code>admin123</code> (غيّرها فورًا)</p>
    </body></html>
    """)

@app.get("/login", response_class=HTMLResponse)
def get_login(): return login_page()

@app.post("/login")
def post_login(username: str=Form(...), password: str=Form(...)):
    u = load_users().get(username)
    if not u or sha256(password) != u.get("pass_sha256"):
        return login_page("Invalid credentials")
    sess = create_session(username)
    audit(username, "login", {})
    resp = RedirectResponse(url="/", status_code=302)
    resp.set_cookie("tremix_session", sess, httponly=True)
    return resp

@app.get("/logout")
def logout(request: Request):
    u = get_current_user(request)
    if u:
        destroy_session(u["session_token"])
        audit(u["username"], "logout", {})
    resp = RedirectResponse(url="/login", status_code=302)
    resp.delete_cookie("tremix_session")
    return resp

@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request):
    try:
        user = require_login(request)
    except PermissionError:
        return RedirectResponse(url="/login", status_code=302)

    role = user["role"]
    can_ops = role in ["admin","operator"]
    can_admin = role == "admin"

    reg = load_registry()
    tasks = load_tasks()[-15:][::-1]
    wst = worker_status()

    svc_rows=""
    for name, info in reg.items():
        st=info.get("status"); pid=info.get("pid"); port=info.get("port")
        alive=False
        if pid:
            try: alive = is_pid_alive(int(pid))
            except: alive=False
        url=f"http://{DEFAULT_HOST}:{port}" if port else "-"
        actions=f"<a href='/svc/logs/{name}'>Logs</a>"
        if can_ops:
            actions=(f"<a href='/svc/start/{name}'>Start</a> | "
                     f"<a href='/svc/stop/{name}'>Stop</a> | "
                     f"<a href='/svc/restart/{name}'>Restart</a> | "
                     f"<a href='/svc/logs/{name}'>Logs</a>")
        svc_rows += f"<tr><td><b>{name}</b></td><td>{st}</td><td>{alive}</td><td>{pid or '-'}</td><td>{port or '-'}</td><td>{url}</td><td>{actions}</td></tr>"

    task_rows=""
    for t in tasks:
        task_rows += f"<tr><td>{t.get('id')}</td><td>{t.get('status')}</td><td>{(t.get('data') or '')[:90]}</td></tr>"
    if not task_rows:
        task_rows = "<tr><td colspan='3'>No tasks yet.</td></tr>"

    create_service_form = ""
    add_task_form = ""
    worker_links = ""
    if can_ops:
        create_service_form = """
        <h3>Create Service</h3>
        <form method="post" action="/svc/create">
          <input name="name" placeholder="service name" required />
          <button type="submit">Create</button>
        </form>"""
        add_task_form = """
        <h3>Add Task</h3>
        <form method="post" action="/tasks/add">
          <input name="data" placeholder="ضع نص المشكلة/اللوق هنا" style="width:70%" required />
          <button type="submit">Queue</button>
        </form>"""
        worker_links = "<a href='/tasks/worker/start'>Start Worker</a> | <a href='/tasks/worker/stop'>Stop Worker</a> |"

    tokens_box = ""
    users_box = ""
    if can_admin:
        tokens = load_tokens()
        tok_rows=""
        for tk, info in list(tokens.items())[:20]:
            tok_rows += f"<tr><td><code>{tk[:10]}…</code></td><td>{info.get('user')}</td><td>{info.get('label','')}</td><td>{info.get('revoked')}</td></tr>"
        if not tok_rows: tok_rows = "<tr><td colspan='4'>No tokens.</td></tr>"
        tokens_box = f"""
        <div class="box">
          <h2>🔑 API Tokens (admin)</h2>
          <p>Header: <code>X-API-Token: &lt;token&gt;</code> | Rate: {RL_MAX_REQ}/{RL_WINDOW_SEC}s</p>
          <table><tr><th>Token</th><th>User</th><th>Label</th><th>Revoked</th></tr>{tok_rows}</table>
          <h3>Create Token</h3>
          <form method="post" action="/admin/tokens/create">
            <input name="username" placeholder="username" required />
            <input name="label" placeholder="label(optional)" />
            <button type="submit">Create</button>
          </form>
          <h3>Revoke Token</h3>
          <form method="post" action="/admin/tokens/revoke">
            <input name="token" placeholder="token" style="width:60%" required />
            <button type="submit">Revoke</button>
          </form>
        </div>
        """
        users = load_users()
        urows=""
        for uname, uinfo in users.items():
            urows += f"<tr><td>{uname}</td><td>{uinfo.get('role')}</td></tr>"
        users_box = f"""
        <div class="box">
          <h2>👥 Users (admin)</h2>
          <table><tr><th>Username</th><th>Role</th></tr>{urows}</table>
          <h3>Create/Update User</h3>
          <form method="post" action="/admin/users/upsert">
            <input name="username" placeholder="username" required />
            <input name="password" placeholder="new password" required />
            <select name="role">
              <option value="viewer">viewer</option>
              <option value="operator">operator</option>
              <option value="admin">admin</option>
            </select>
            <button type="submit">Save</button>
          </form>
          <h3>Change My Password</h3>
          <form method="post" action="/admin/users/change_my_password">
            <input name="new_password" placeholder="new password" required />
            <button type="submit">Change</button>
          </form>
        </div>
        """

    ai_status = "ollama" if OLLAMA_HOST else ("openai" if OPENAI_API_KEY else "heuristic")
    return HTMLResponse(f"""
    <html><head><meta charset="utf-8"/><title>Tremix</title>
    <style>
      body {{ font-family:sans-serif; padding:16px; }}
      table {{ border-collapse:collapse; width:100%; }}
      th,td {{ border:1px solid #ddd; padding:8px; }}
      th {{ background:#f3f3f3; }}
      .box {{ border:1px solid #ddd; padding:12px; border-radius:10px; margin-top:14px; }}
      code {{ background:#f7f7f7; padding:2px 6px; border-radius:6px; }}
      .top {{ display:flex; justify-content:space-between; align-items:center; }}
      .pill {{ padding:4px 10px; border:1px solid #ddd; border-radius:999px; }}
    </style></head><body>

    <div class="top">
      <h1>🚀 Tremix Control Plane (FULL)</h1>
      <div>
        <span class="pill">user: <b>{user['username']}</b></span>
        <span class="pill">role: <b>{role}</b></span>
        <span class="pill">AI: <b>{ai_status}</b></span>
        <a style="margin-left:12px" href="/logout">Logout</a>
      </div>
    </div>

    <div class="box">
      <h2>Services</h2>
      <table>
        <tr><th>Name</th><th>Status</th><th>Alive</th><th>PID</th><th>Port</th><th>URL</th><th>Actions</th></tr>
        {svc_rows or "<tr><td colspan='7'>No services.</td></tr>"}
      </table>
      {create_service_form}
    </div>

    <div class="box">
      <h2>🧠 Task Queue</h2>
      <p>Worker: <b>{'RUNNING' if wst.get('running') else 'STOPPED'}</b> (pid={wst.get('pid','-')})</p>
      <p>{worker_links} <a href="/tremix/logs">Tremix Logs</a> | <a href="/audit">Audit</a></p>
      {add_task_form}
      <h3>Recent Tasks</h3>
      <table><tr><th>ID</th><th>Status</th><th>Data</th></tr>{task_rows}</table>
      <p>Outbox: <code>~/Tremix/outbox</code> | Memory: <code>~/Tremix/memory.json</code></p>
    </div>

    <div class="box">
      <h2>📂 File Doctors (Upload + AI)</h2>
      <form method="post" action="/files/analyze" enctype="multipart/form-data">
        <input type="file" name="file" required />
        <input type="text" name="instruction" placeholder="اختياري: ركّز على ايش؟" style="width:55%" />
        <button type="submit">Analyze</button>
      </form>
      <p>Results saved in <code>~/Tremix/outbox</code> (json)</p>
    </div>

    {users_box}
    {tokens_box}

    </body></html>
    """)

# ---------- UI endpoints (protected) ----------
@app.post("/svc/create")
def svc_create(request: Request, name: str=Form(...)):
    user = require_login(request); require_role(user, ["admin","operator"])
    create_service(name); audit(user["username"], "svc_create", {"name": name})
    return RedirectResponse(url="/", status_code=302)

@app.get("/svc/start/{name}")
def svc_start(request: Request, name: str):
    user = require_login(request); require_role(user, ["admin","operator"])
    start_service(name); audit(user["username"], "svc_start", {"name": name})
    return RedirectResponse(url="/", status_code=302)

@app.get("/svc/stop/{name}")
def svc_stop(request: Request, name: str):
    user = require_login(request); require_role(user, ["admin","operator"])
    stop_service(name); audit(user["username"], "svc_stop", {"name": name})
    return RedirectResponse(url="/", status_code=302)

@app.get("/svc/restart/{name}")
def svc_restart(request: Request, name: str):
    user = require_login(request); require_role(user, ["admin","operator"])
    restart_service(name); audit(user["username"], "svc_restart", {"name": name})
    return RedirectResponse(url="/", status_code=302)

@app.get("/svc/logs/{name}", response_class=HTMLResponse)
def svc_logs(request: Request, name: str):
    user = require_login(request)
    info = load_registry().get(name, {})
    path = info.get("svc_log") or os.path.join(BASE_DIR, f"{name}.log")
    audit(user["username"], "svc_logs", {"name": name})
    return HTMLResponse(f"<pre>{tail(path, 260)}</pre><p><a href='/'>Back</a></p>")

@app.post("/tasks/add")
def ui_task_add(request: Request, data: str=Form(...)):
    user = require_login(request); require_role(user, ["admin","operator"])
    tid = add_task(data); audit(user["username"], "task_add", {"id": tid})
    return RedirectResponse(url="/", status_code=302)

@app.get("/tasks/worker/start")
def ui_worker_start(request: Request):
    user = require_login(request); require_role(user, ["admin","operator"])
    st = worker_start_bg(); audit(user["username"], "worker_start", st)
    return RedirectResponse(url="/", status_code=302)

@app.get("/tasks/worker/stop")
def ui_worker_stop(request: Request):
    user = require_login(request); require_role(user, ["admin","operator"])
    st = worker_stop_bg(); audit(user["username"], "worker_stop", st)
    return RedirectResponse(url="/", status_code=302)

@app.post("/admin/users/upsert")
def admin_users_upsert(request: Request, username: str=Form(...), password: str=Form(...), role: str=Form(...)):
    user = require_login(request); require_role(user, ["admin"])
    if role not in ["admin","operator","viewer"]:
        return forbid_page("Invalid role")
    users = load_users()
    users[username] = {"role": role, "pass_sha256": sha256(password)}
    save_users(users)
    audit(user["username"], "user_upsert", {"username": username, "role": role})
    return RedirectResponse(url="/", status_code=302)

@app.post("/admin/users/change_my_password")
def admin_change_my_password(request: Request, new_password: str=Form(...)):
    user = require_login(request); require_role(user, ["admin"])
    users = load_users()
    users[user["username"]]["pass_sha256"] = sha256(new_password)
    save_users(users)
    audit(user["username"], "password_change", {})
    return RedirectResponse(url="/", status_code=302)

@app.post("/admin/tokens/create")
def admin_tokens_create(request: Request, username: str=Form(...), label: str=Form(default="")):
    user = require_login(request); require_role(user, ["admin"])
    if username not in load_users():
        return forbid_page("Unknown user")
    tk = create_api_token(username, label=label)
    audit(user["username"], "token_create", {"for_user": username, "label": label})
    return HTMLResponse(f"<h3>✅ Token Created</h3><p><code>{tk}</code></p><p><a href='/'>Back</a></p>")

@app.post("/admin/tokens/revoke")
def admin_tokens_revoke(request: Request, token: str=Form(...)):
    user = require_login(request); require_role(user, ["admin"])
    revoke_api_token(token)
    audit(user["username"], "token_revoke", {"token_prefix": token[:10]})
    return RedirectResponse(url="/", status_code=302)

@app.get("/tremix/logs", response_class=HTMLResponse)
def ui_tremix_logs(request: Request):
    user = require_login(request)
    audit(user["username"], "tremix_logs", {})
    return HTMLResponse(f"<pre>{tail(LOG_FILE, 320)}</pre><p><a href='/'>Back</a></p>")

@app.get("/audit", response_class=HTMLResponse)
def ui_audit(request: Request):
    user = require_login(request); require_role(user, ["admin"])
    return HTMLResponse(f"<pre>{tail(AUDIT_FILE, 320)}</pre><p><a href='/'>Back</a></p>")

# ---------- UI file analyze ----------
@app.post("/files/analyze")
async def ui_files_analyze(request: Request, file: UploadFile=File(...), instruction: str=Form(default="")):
    user = require_login(request); require_role(user, ["admin","operator"])
    ensure_dirs()
    safe = os.path.basename(file.filename or "upload.bin")
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_path = os.path.join(INBOX_DIR, f"{ts}_{safe}")
    data = await file.read()
    with open(save_path, "wb") as f: f.write(data)

    text = extract_text(save_path)
    ai = ai_analyze(text, instruction=instruction)

    result = {
        "type": "file_analysis",
        "file": save_path,
        "instruction": instruction,
        "extracted_chars": len(text),
        "ai": ai,
        "created_at": datetime.now().isoformat()
    }
    out_path = os.path.join(OUTBOX_DIR, f"file_{ts}_{os.path.splitext(safe)[0]}.json")
    save_json(out_path, result)
    add_memory("file_result", {"file": save_path, "out": out_path})
    audit(user["username"], "file_analyze", {"file": safe, "out": os.path.basename(out_path)})
    return HTMLResponse(f"<h3>✅ Done</h3><p>Saved: <code>{out_path}</code></p><p><a href='/'>Back</a></p>")

# ---------- API endpoints (token protected) ----------
def api_forbidden(status=403):
    return JSONResponse({"ok": False, "error": "forbidden"}, status_code=status)

@app.get("/api/v1/ping")
def api_ping(x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    return {"ok": True, "user": au["username"], "role": au["role"], "ts": datetime.now().isoformat()}

@app.get("/api/v1/registry")
def api_registry(x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    audit(au["username"], "api_registry", {})
    return {"ok": True, "registry": load_registry()}

@app.post("/api/v1/task/add")
def api_task_add(data: str=Form(...), x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    tid = add_task(data)
    audit(au["username"], "api_task_add", {"id": tid})
    return {"ok": True, "task_id": tid}

@app.get("/api/v1/tasks")
def api_tasks(x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    audit(au["username"], "api_tasks_list", {})
    return {"ok": True, "tasks": load_tasks()}

@app.post("/api/v1/worker/start")
def api_worker_start(x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    st = worker_start_bg()
    audit(au["username"], "api_worker_start", st)
    return {"ok": True, "status": st}

@app.post("/api/v1/worker/stop")
def api_worker_stop(x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    st = worker_stop_bg()
    audit(au["username"], "api_worker_stop", st)
    return {"ok": True, "status": st}

@app.post("/api/v1/service/start")
def api_service_start(name: str=Form(...), x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    start_service(name)
    audit(au["username"], "api_svc_start", {"name": name})
    return {"ok": True, "info": load_registry().get(name,{})}

@app.post("/api/v1/service/stop")
def api_service_stop(name: str=Form(...), x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    stop_service(name)
    audit(au["username"], "api_svc_stop", {"name": name})
    return {"ok": True}

@app.post("/api/v1/file/analyze")
async def api_file_analyze(
    file: UploadFile = File(...),
    instruction: str = Form(default=""),
    x_api_token: Optional[str]=Header(default=None, alias="X-API-Token")
):
    au, err = require_api(x_api_token)
    if err: return err
    if au["role"] not in ["admin","operator"]: return api_forbidden()
    ensure_dirs()

    safe = os.path.basename(file.filename or "upload.bin")
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_path = os.path.join(INBOX_DIR, f"{ts}_{safe}")
    data = await file.read()
    with open(save_path, "wb") as f: f.write(data)

    text = extract_text(save_path)
    ai = ai_analyze(text, instruction=instruction)

    result = {
        "ok": True,
        "file": save_path,
        "instruction": instruction,
        "extracted_chars": len(text),
        "ai": ai,
        "created_at": datetime.now().isoformat()
    }
    out_path = os.path.join(OUTBOX_DIR, f"file_{ts}_{os.path.splitext(safe)[0]}.json")
    save_json(out_path, result)
    add_memory("file_result", {"file": save_path, "out": out_path})
    audit(au["username"], "api_file_analyze", {"file": safe, "out": os.path.basename(out_path)})
    return {"ok": True, "saved": out_path, "result": result}

# ---------------- CLI ----------------
def cli_help():
    print(f"""
Run dashboard:
  python3 ~/tremix_master.py dashboard

Run worker (foreground):
  python3 ~/tremix_master.py worker

Dashboard:
  http://{DEFAULT_HOST}:{DASHBOARD_PORT}

Default admin:
  admin / admin123
""".strip())

def main():
    ensure_dirs()
    if len(sys.argv) >= 2 and sys.argv[1].lower() == "dashboard":
        print("✅ Tremix FULL Online")
        print(f"🌐 Dashboard: http://{DEFAULT_HOST}:{DASHBOARD_PORT}")
        uvicorn.run(app, host="0.0.0.0", port=DASHBOARD_PORT, log_level="warning")
    elif len(sys.argv) >= 2 and sys.argv[1].lower() == "worker":
        worker_loop()
    else:
        cli_help()

if __name__ == "__main__":
    main()
