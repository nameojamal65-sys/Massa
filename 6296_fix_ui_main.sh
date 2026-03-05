#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home
# shellcheck disable=SC1091
source .venv/bin/activate

MAIN="app/main.py"
if [ ! -f "$MAIN" ]; then
  echo "❌ ما لقيت $MAIN"
  exit 1
fi

echo "✅ Backup main.py -> app/main.py.bak"
cp -f "$MAIN" "$MAIN.bak"

echo "✅ Sanitizing main.py (remove accidental pasted UI junk if any)..."
# نحذف أي HTML/Jinja أو JS انزرع بالغلط داخل main.py
python - <<'PY'
import re, pathlib
p = pathlib.Path("app/main.py")
s = p.read_text(encoding="utf-8", errors="ignore")

# cut off anything that looks like pasted HTML template
markers = ["<!doctype html", "<html", "{% block", "const TOKEN_KEY", "</script>", "</body>", "</html>"]
cut = None
for m in markers:
    idx = s.find(m)
    if idx != -1:
        cut = idx if cut is None else min(cut, idx)
if cut is not None:
    s = s[:cut].rstrip() + "\n"

# remove lines that look like shell-pasted python prompts or weird heredoc artifacts
bad_patterns = [
    r"^> .*?$",
    r"^bash: .*?$",
    r"^No command .*?$",
]
for pat in bad_patterns:
    s = re.sub(pat, "", s, flags=re.M)

# collapse too many blank lines
s = re.sub(r"\n{4,}", "\n\n", s)

p.write_text(s, encoding="utf-8")
print("main.py sanitized")
PY

echo "✅ Ensuring UI router files exist..."
mkdir -p app/web/templates

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

  function getToken() { return localStorage.getItem(TOKEN_KEY) || ""; }

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
    if (!headers["Content-Type"] && !(opts.body instanceof FormData)) headers["Content-Type"] = "application/json";

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
</div>

<script>
  if (getToken()) window.location.href = "/ui";

  async function doLogin() {
    const u = document.getElementById("username").value.trim();
    const p = document.getElementById("password").value;
    const msg = document.getElementById("msg");
    msg.textContent = "…";
    try {
      const tokens = await api("/api/v1/auth/login", { method: "POST", body: JSON.stringify({username: u, password: p}) });
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
  <div class="muted">افتح Swagger من هنا: <code>/docs</code></div>
</div>

<div class="card">
  <h3 style="margin-top:0;">Quick Links</h3>
  <div class="row">
    <button onclick="window.location.href='/docs'">Open /docs</button>
    <button onclick="window.location.href='/openapi.json'">Open openapi.json</button>
  </div>
</div>

<div class="card">
  <h3 style="margin-top:0;">Health</h3>
  <button onclick="loadHealth()">Check /health</button>
  <pre id="healthOut" class="mono" style="white-space:pre-wrap;"></pre>
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
</script>
{% endblock %}
HTML

echo "✅ Ensuring main.py imports & includes UI router (safe append)..."
python - <<'PY'
import pathlib, re
p = pathlib.Path("app/main.py")
s = p.read_text(encoding="utf-8", errors="ignore")

imp = "from app.web.router import router as ui_router"
if imp not in s:
    # put after first block of imports
    lines = s.splitlines(True)
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("from ") or line.startswith("import "):
            insert_at = i+1
        else:
            if i > 0: break
    lines.insert(insert_at, imp + "\n")
    s = "".join(lines)

# add include_router near other include_router calls; if none, add after app creation
if "app.include_router(ui_router)" not in s:
    m = re.search(r"^app\s*=\s*FastAPI\(.*?\)\s*$", s, flags=re.M)
    if m:
        # insert right after app = FastAPI(...)
        idx = m.end()
        s = s[:idx] + "\napp.include_router(ui_router)\n" + s[idx:]
    else:
        # fallback: append at end
        s = s.rstrip() + "\n\napp.include_router(ui_router)\n"

p.write_text(s, encoding="utf-8")
print("main.py updated")
PY

echo "✅ Compile check..."
python -m py_compile app/web/router.py
python -m py_compile app/main.py

echo "🎉 Fixed. Now run:"
echo "uvicorn app.main:app --host 127.0.0.1 --port 9000"
echo "Open: http://127.0.0.1:9000/ui/login"
