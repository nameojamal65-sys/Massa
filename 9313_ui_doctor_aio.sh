#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HOME_DIR="/data/data/com.termux/files/home"
cd "$HOME_DIR"

echo "🛠️ UI Doctor AIO — starting..."
echo "📍 HOME: $HOME_DIR"

if [ ! -d ".venv" ]; then
  echo "❌ .venv غير موجودة في $HOME_DIR"
  echo "   أنشئ venv أولاً ثم أعد التشغيل."
  exit 1
fi

# shellcheck disable=SC1091
source .venv/bin/activate

echo "✅ Installing/Updating Jinja2..."
pip -q install -U jinja2 >/dev/null

echo "✅ Creating UI folders..."
mkdir -p app/web/templates

echo "✅ Writing app/web/router.py ..."
cat > app/web/router.py <<'PY'
from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates

templates = Jinja2Templates(directory="app/web/templates")
router = APIRouter(tags=["ui"])


@router.get("/ui", response_class=HTMLResponse)
def ui_index(request: Request):
    return templates.TemplateResponse("dashboard.html", {"request": request})


@router.get("/ui/login", response_class=HTMLResponse)
def ui_login(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})


@router.get("/ui/logout")
def ui_logout():
    return RedirectResponse(url="/ui/login", status_code=302)


@router.get("/", include_in_schema=False)
def root_redirect():
    return RedirectResponse(url="/ui", status_code=302)
PY

echo "✅ Writing templates..."
cat > app/web/templates/base.html <<'HTML'
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>PAI6 Sovereign Core — UI</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial; margin: 0; background:#0b0f14; color:#e7eef8; }
    header { padding: 16px 20px; background:#0f1621; border-bottom:1px solid #1c2a3a; display:flex; align-items:center; justify-content:space-between; }
    .brand { font-weight:700; letter-spacing:.3px; }
    .container { padding: 18px 20px; max-width: 1100px; margin: 0 auto; }
    .card { background:#0f1621; border:1px solid #1c2a3a; border-radius: 14px; padding: 16px; margin-bottom: 14px; }
    .row { display:flex; gap: 10px; flex-wrap: wrap; }
    .row > * { flex: 1; min-width: 220px; }
    input, select, textarea, button {
      width: 100%; padding: 10px 12px; border-radius: 10px;
      border:1px solid #23364d; background:#0b0f14; color:#e7eef8; outline: none;
    }
    button { cursor:pointer; background:#1b3b63; border-color:#2a568f; font-weight:700; }
    button:hover { background:#234d80; }
    .muted { color:#9fb2c9; font-size: 13px; }
    .ok { color:#69f0ae; }
    .bad { color:#ff6b6b; }
    table { width:100%; border-collapse: collapse; }
    th, td { border-bottom: 1px solid #1c2a3a; padding: 10px; text-align: right; font-size: 14px; }
    th { color:#9fb2c9; font-weight: 700; }
    code { background:#0b0f14; padding: 2px 6px; border-radius: 8px; border:1px solid #1c2a3a; }
    .top-actions { display:flex; gap: 10px; align-items:center; }
    .linkbtn { background: transparent; border:1px solid #23364d; }
    .linkbtn:hover { background:#0b0f14; }
    .split { display:flex; gap: 12px; flex-wrap: wrap; }
    .split > .card { flex: 1; min-width: 320px; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New"; }
  </style>
</head>
<body>
<header>
  <div class="brand">PAI6 Sovereign Core — Admin UI</div>
  <div class="top-actions">
    <div id="authState" class="muted">checking…</div>
    <button class="linkbtn" onclick="logout()">Logout</button>
  </div>
</header>

<div class="container">
  {% block content %}{% endblock %}
</div>

<script>
  const TOKEN_KEY = "pai6_access_token";

  function getToken() {
    return localStorage.getItem(TOKEN_KEY) || "";
  }

  function setAuthState() {
    const el = document.getElementById("authState");
    if (!el) return;
    el.textContent = getToken() ? "AUTH: OK" : "AUTH: MISSING";
    el.className = getToken() ? "ok" : "bad";
  }

  function logout() {
    localStorage.removeItem(TOKEN_KEY);
    window.location.href = "/ui/login";
  }

  async function api(path, opts={}) {
    const headers = opts.headers || {};
    const token = getToken();
    if (token) headers["Authorization"] = `Bearer ${token}`;
    if (!headers["Content-Type"] && !(opts.body instanceof FormData)) {
      headers["Content-Type"] = "application/json";
    }
    const res = await fetch(path, {...opts, headers});
    const text = await res.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    if (!res.ok) {
      const msg = (data && data.error && data.error.message) || (data && data.detail) || text || `HTTP ${res.status}`;
      throw new Error(msg);
    }
    return data;
  }

  setAuthState();
</script>
</body>
</html>
HTML

cat > app/web/templates/login.html <<'HTML'
{% extends "base.html" %}
{% block content %}

<div class="card">
  <h2 style="margin:0 0 8px 0;">تسجيل الدخول</h2>
  <div class="muted">سجّل دخولك عبر API ثم خزّن التوكن محليًا للواجهة.</div>
</div>

<div class="card">
  <div class="row">
    <div>
      <label class="muted">Username</label>
      <input id="username" placeholder="admin" />
    </div>
    <div>
      <label class="muted">Password</label>
      <input id="password" type="password" placeholder="••••••••" />
    </div>
  </div>

  <div style="height:10px"></div>
  <button onclick="doLogin()">Login</button>

  <div id="msg" class="muted" style="margin-top:10px"></div>

  <hr style="border:0;border-top:1px solid #1c2a3a;margin:16px 0;" />

  <div class="muted">
    إذا لسه ما عملت bootstrap:
    افتح <code>/docs</code> أو استعمل curl على
    <code>/api/v1/tenants/bootstrap</code>.
  </div>
</div>

<script>
  if (getToken()) window.location.href = "/ui";

  async function doLogin() {
    const u = document.getElementById("username").value.trim();
    const p = document.getElementById("password").value;
    const msg = document.getElementById("msg");
    msg.textContent = "…";
    try {
      const tokens = await api("/api/v1/auth/login", {
        method: "POST",
        body: JSON.stringify({username: u, password: p})
      });
      localStorage.setItem("pai6_access_token", tokens.access_token);
      msg.textContent = "✅ Logged in";
      window.location.href = "/ui";
    } catch (e) {
      msg.textContent = "❌ " + e.message;
    }
  }
</script>

{% endblock %}
HTML

cat > app/web/templates/dashboard.html <<'HTML'
{% extends "base.html" %}
{% block content %}

<div class="card">
  <h2 style="margin:0 0 8px 0;">لوحة التحكم</h2>
  <div class="muted">Users • API Keys • Tasks • Files • AI Proxy</div>
</div>

<div class="split">
  <div class="card">
    <h3 style="margin-top:0;">Health</h3>
    <button onclick="loadHealth()">Check /health</button>
    <pre id="healthOut" class="mono" style="white-space:pre-wrap;"></pre>
  </div>

  <div class="card">
    <h3 style="margin-top:0;">Create User</h3>
    <div class="row">
      <div><input id="cu_username" placeholder="newuser" /></div>
      <div><input id="cu_password" type="password" placeholder="password123" /></div>
      <div>
        <select id="cu_role">
          <option value="viewer">viewer</option>
          <option value="developer">developer</option>
          <option value="admin">admin</option>
        </select>
      </div>
    </div>
    <div style="height:10px"></div>
    <button onclick="createUser()">Create</button>
    <div id="cu_msg" class="muted" style="margin-top:10px"></div>
  </div>
</div>

<div class="split">
  <div class="card">
    <h3 style="margin-top:0;">Users</h3>
    <button onclick="loadUsers()">Refresh</button>
    <div style="height:10px"></div>
    <table>
      <thead><tr><th>ID</th><th>Username</th><th>Role</th><th>Created</th></tr></thead>
      <tbody id="usersTbody"></tbody>
    </table>
  </div>

  <div class="card">
    <h3 style="margin-top:0;">API Keys</h3>
    <div class="row">
      <div><input id="ak_label" placeholder="label (optional)" /></div>
      <div><button onclick="createKey()">Create Key</button></div>
    </div>
    <div id="ak_msg" class="muted" style="margin-top:10px"></div>
    <div style="height:10px"></div>
    <button onclick="loadKeys()">Refresh</button>
    <table>
      <thead><tr><th>ID</th><th>Prefix</th><th>Label</th><th>Revoked</th><th></th></tr></thead>
      <tbody id="keysTbody"></tbody>
    </table>
  </div>
</div>

<div class="split">
  <div class="card">
    <h3 style="margin-top:0;">Tasks</h3>
    <div class="row">
      <div><input id="task_type" value="echo" /></div>
      <div><textarea id="task_input" rows="3" placeholder='{"x":1}'></textarea></div>
    </div>
    <div style="height:10px"></div>
    <button onclick="createTask()">Create Task</button>
    <div id="task_msg" class="muted" style="margin-top:10px"></div>

    <hr style="border:0;border-top:1px solid #1c2a3a;margin:16px 0;" />

    <button onclick="loadTasks()">Refresh</button>
    <table>
      <thead><tr><th>ID</th><th>Type</th><th>Status</th><th>Updated</th><th></th></tr></thead>
      <tbody id="tasksTbody"></tbody>
    </table>
  </div>

  <div class="card">
    <h3 style="margin-top:0;">Files</h3>
    <input id="file_input" type="file" />
    <div style="height:10px"></div>
    <button onclick="uploadFile()">Upload</button>
    <div id="file_msg" class="muted" style="margin-top:10px"></div>

    <hr style="border:0;border-top:1px solid #1c2a3a;margin:16px 0;" />

    <button onclick="loadFiles()">Refresh</button>
    <table>
      <thead><tr><th>ID</th><th>Name</th><th>Size</th><th>SHA</th><th></th></tr></thead>
      <tbody id="filesTbody"></tbody>
    </table>
  </div>
</div>

<div class="card">
  <h3 style="margin-top:0;">AI Proxy</h3>
  <div class="row">
    <div><input id="ai_model" placeholder="model (optional)" value="gpt-4.1-mini" /></div>
    <div><input id="ai_input" placeholder="input" value="hello" /></div>
  </div>
  <div style="height:10px"></div>
  <button onclick="callAI()">Send</button>
  <pre id="aiOut" class="mono" style="white-space:pre-wrap;"></pre>
</div>

<script>
  if (!getToken()) window.location.href = "/ui/login";

  async function loadHealth() {
    const out = document.getElementById("healthOut");
    out.textContent = "…";
    try {
      const j = await api("/health", { method: "GET" });
      out.textContent = JSON.stringify(j, null, 2);
    } catch(e) {
      out.textContent = "ERROR: " + e.message;
    }
  }

  async function loadUsers() {
    const tbody = document.getElementById("usersTbody");
    tbody.innerHTML = "<tr><td colspan='4' class='muted'>…</td></tr>";
    try {
      const users = await api("/api/v1/users/", { method: "GET" });
      tbody.innerHTML = users.map(u =>
        `<tr><td>${u.id}</td><td>${u.username}</td><td>${u.role}</td><td>${u.created_at}</td></tr>`
      ).join("");
    } catch(e) {
      tbody.innerHTML = `<tr><td colspan='4' class='bad'>${e.message}</td></tr>`;
    }
  }

  async function createUser() {
    const msg = document.getElementById("cu_msg");
    msg.textContent = "…";
    try {
      const payload = {
        username: document.getElementById("cu_username").value.trim(),
        password: document.getElementById("cu_password").value,
        role: document.getElementById("cu_role").value
      };
      await api("/api/v1/users/", { method: "POST", body: JSON.stringify(payload) });
      msg.textContent = "✅ created";
      await loadUsers();
    } catch(e) {
      msg.textContent = "❌ " + e.message;
    }
  }

  async function loadKeys() {
    const tbody = document.getElementById("keysTbody");
    tbody.innerHTML = "<tr><td colspan='5' class='muted'>…</td></tr>";
    try {
      const keys = await api("/api/v1/apikeys/", { method: "GET" });
      tbody.innerHTML = keys.map(k =>
        `<tr>
          <td>${k.id}</td><td>${k.key_prefix}</td><td>${k.label ?? ""}</td><td>${k.revoked}</td>
          <td><button class="linkbtn" onclick="revokeKey(${k.id})">Revoke</button></td>
        </tr>`
      ).join("");
    } catch(e) {
      tbody.innerHTML = `<tr><td colspan='5' class='bad'>${e.message}</td></tr>`;
    }
  }

  async function createKey() {
    const msg = document.getElementById("ak_msg");
    msg.textContent = "…";
    try {
      const label = document.getElementById("ak_label").value.trim();
      await api("/api/v1/apikeys/", { method: "POST", body: JSON.stringify({label: label || null}) });
      msg.textContent = "✅ created";
      await loadKeys();
    } catch(e) {
      msg.textContent = "❌ " + e.message;
    }
  }

  async function revokeKey(id) {
    try {
      await api(`/api/v1/apikeys/${id}/revoke`, { method: "POST" });
      await loadKeys();
    } catch(e) {
      alert(e.message);
    }
  }

  async function loadTasks() {
    const tbody = document.getElementById("tasksTbody");
    tbody.innerHTML = "<tr><td colspan='5' class='muted'>…</td></tr>";
    try {
      const tasks = await api("/api/v1/tasks/", { method: "GET" });
      tbody.innerHTML = tasks.map(t =>
        `<tr>
          <td>${t.id}</td><td>${t.type}</td><td>${t.status}</td><td>${t.updated_at}</td>
          <td><button class="linkbtn" onclick="cancelTask(${t.id})">Cancel</button></td>
        </tr>`
      ).join("");
    } catch(e) {
      tbody.innerHTML = `<tr><td colspan='5' class='bad'>${e.message}</td></tr>`;
    }
  }

  async function createTask() {
    const msg = document.getElementById("task_msg");
    msg.textContent = "…";
    try {
      const type = document.getElementById("task_type").value.trim();
      const raw = document.getElementById("task_input").value.trim() || "{}";
      const input_json = JSON.parse(raw);
      await api("/api/v1/tasks/", { method: "POST", body: JSON.stringify({type, input_json}) });
      msg.textContent = "✅ created";
      await loadTasks();
    } catch(e) {
      msg.textContent = "❌ " + e.message;
    }
  }

  async function cancelTask(id) {
    try {
      await api(`/api/v1/tasks/${id}/cancel`, { method: "POST" });
      await loadTasks();
    } catch(e) {
      alert(e.message);
    }
  }

  async function loadFiles() {
    const tbody = document.getElementById("filesTbody");
    tbody.innerHTML = "<tr><td colspan='5' class='muted'>…</td></tr>";
    try {
      const files = await api("/api/v1/files/", { method: "GET" });
      tbody.innerHTML = files.map(f =>
        `<tr>
          <td>${f.id}</td><td>${f.filename}</td><td>${f.size}</td><td>${f.sha256.slice(0,12)}…</td>
          <td><button class="linkbtn" onclick="deleteFile(${f.id})">Delete</button></td>
        </tr>`
      ).join("");
    } catch(e) {
      tbody.innerHTML = `<tr><td colspan='5' class='bad'>${e.message}</td></tr>`;
    }
  }

  async function uploadFile() {
    const msg = document.getElementById("file_msg");
    msg.textContent = "…";
    try {
      const fi = document.getElementById("file_input");
      if (!fi.files || !fi.files[0]) throw new Error("Choose a file first");
      const fd = new FormData();
      fd.append("file", fi.files[0]);
      await api("/api/v1/files/upload", { method: "POST", body: fd });
      msg.textContent = "✅ uploaded";
      await loadFiles();
    } catch(e) {
      msg.textContent = "❌ " + e.message;
    }
  }

  async function deleteFile(id) {
    try {
      await api(`/api/v1/files/${id}`, { method: "DELETE" });
      await loadFiles();
    } catch(e) {
      alert(e.message);
    }
  }

  async function callAI() {
    const out = document.getElementById("aiOut");
    out.textContent = "…";
    try {
      const model = document.getElementById("ai_model").value.trim() || null;
      const input = document.getElementById("ai_input").value;
      const r = await api("/api/v1/ai/proxy", { method: "POST", body: JSON.stringify({model, input}) });
      out.textContent = JSON.stringify(r, null, 2);
    } catch(e) {
      out.textContent = "ERROR: " + e.message;
    }
  }

  loadUsers();
  loadKeys();
  loadTasks();
  loadFiles();
</script>

{% endblock %}
HTML

echo "✅ Patching app/main.py safely (with backup)..."
MAIN="app/main.py"
if [ ! -f "$MAIN" ]; then
  echo "❌ ما لقيت $MAIN"
  exit 1
fi

TS="$(date +%Y%m%d_%H%M%S)"
cp -f "$MAIN" "${MAIN}.bak_${TS}"
echo "🧷 Backup: ${MAIN}.bak_${TS}"

python - <<'PY'
from __future__ import annotations
import re
from pathlib import Path

main = Path("app/main.py")
s = main.read_text().splitlines()

IMP = "from app.web.router import router as ui_router"
INCL = "app.include_router(ui_router)"

def leading_ws(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]

# 0) remove accidental top-level "return app" if exists
out = []
for line in s:
    if line.strip() == "return app" and len(leading_ws(line)) == 0:
        # drop it
        continue
    out.append(line)
s = out

# 1) ensure import exists (place after imports block)
if not any(l.strip() == IMP for l in s):
    last_import = -1
    for i, line in enumerate(s):
        if re.match(r'^\s*(from\s+\S+\s+import\s+|import\s+\S+)', line):
            last_import = i
        else:
            if last_import >= 0:
                break
    insert_at = last_import + 1 if last_import >= 0 else 0
    s.insert(insert_at, IMP)

# 2) ensure include_router exists — prefer inserting right after app = FastAPI(...)
if any(re.search(r'\bapp\.include_router\(\s*ui_router\s*\)', l) for l in s):
    main.write_text("\n".join(s) + "\n")
    print("ui_router already included")
    raise SystemExit(0)

# helper: insert after first "app = FastAPI" within a block (module or inside def)
def insert_after_app_fastapi(lines: list[str], start: int = 0, end: int | None = None) -> bool:
    if end is None: end = len(lines)
    for i in range(start, end):
        if re.search(r'^\s*app\s*=\s*FastAPI\b', lines[i]):
            ws = leading_ws(lines[i])
            lines.insert(i + 1, f"{ws}{INCL}")
            return True
    return False

# 2a) detect factory function create_app()/get_app()/make_app() pattern
# If there's a def create_app... and inside it app = FastAPI, insert there.
factory_names = ("create_app", "get_app", "make_app", "build_app")
factory_def_idx = None
factory_indent = None
for i, line in enumerate(s):
    m = re.match(r'^\s*def\s+(' + "|".join(factory_names) + r')\s*\(', line)
    if m:
        factory_def_idx = i
        factory_indent = len(leading_ws(line))
        break

if factory_def_idx is not None:
    # find end of function block (next line with indent <= factory_indent and not blank/comment)
    end = len(s)
    for j in range(factory_def_idx + 1, len(s)):
        lj = s[j]
        if lj.strip() == "" or lj.lstrip().startswith("#"):
            continue
        if len(leading_ws(lj)) <= factory_indent:
            end = j
            break
    if insert_after_app_fastapi(s, factory_def_idx, end):
        main.write_text("\n".join(s) + "\n")
        print("Included ui_router inside factory function.")
        raise SystemExit(0)

# 2b) fallback: module-level app = FastAPI(...)
if insert_after_app_fastapi(s, 0, len(s)):
    main.write_text("\n".join(s) + "\n")
    print("Included ui_router at module level.")
    raise SystemExit(0)

# 2c) couldn't find app = FastAPI
main.write_text("\n".join(s) + "\n")
raise SystemExit("❌ Couldn't find 'app = FastAPI(...)' to attach ui_router. Please check app/main.py structure.")
PY

echo "✅ Compile check..."
python -m py_compile app/web/router.py
python -m py_compile app/main.py

echo
echo "🎉 DONE."
echo "Run server:"
echo "  uvicorn app.main:app --host 127.0.0.1 --port 9000"
echo "Open:"
echo "  http://127.0.0.1:9000/ui/login"
