#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_core"
UI="$ROOT/ui/server.py"

echo "== Sovereign Patch Pack v1 (Zero-Break RC) =="
[ -d "$ROOT" ] || { echo "❌ لم أجد $ROOT"; exit 1; }
[ -f "$UI" ] || { echo "❌ لم أجد $UI"; exit 1; }

mkdir -p "$ROOT/sc_platform" "$ROOT/infra/prod" "$ROOT/ui/static/dash"

# ---------------- sc_platform ----------------
cat > "$ROOT/sc_platform/__init__.py" <<'PY'
# Sovereign Core platform hardening helpers
PY

cat > "$ROOT/sc_platform/flags.py" <<'PY'
import os
def flag(name: str, default: str="0") -> bool:
    return os.getenv(name, default).strip() in ("1","true","True","yes","YES")

SC_VERSION        = os.getenv("SC_VERSION", "1").strip()
SC_FREEZE         = flag("SC_FREEZE", "0")
SC_RATE_LIMIT     = flag("SC_RATE_LIMIT", "0")
SC_NEW_UI         = flag("SC_NEW_UI", "0")   # serve /dash when enabled
PY

cat > "$ROOT/sc_platform/errors.py" <<'PY'
from dataclasses import dataclass
from typing import Any, Dict, Optional

@dataclass
class SCError(Exception):
    code: str
    message: str
    status: int = 400
    details: Optional[Dict[str, Any]] = None

def to_json(err: Exception, correlation_id: str):
    if isinstance(err, SCError):
        return ({
            "ok": False,
            "error": {"code": err.code, "message": err.message, "details": err.details or {}},
            "correlation_id": correlation_id,
        }, err.status)

    return ({
        "ok": False,
        "error": {"code": "INTERNAL_ERROR", "message": "Unexpected server error", "details": {}},
        "correlation_id": correlation_id,
    }, 500)
PY

cat > "$ROOT/sc_platform/middleware.py" <<'PY'
import uuid
from flask import request, g, jsonify
from .flags import SC_VERSION, SC_FREEZE
from .errors import to_json, SCError

CORR_HEADER_IN  = "X-Correlation-Id"
CORR_HEADER_OUT = "X-Correlation-Id"
VER_HEADER_OUT  = "X-SC-Version"

FREEZE_ALLOWLIST_PREFIXES = (
    "/health",
    "/api/status",
    "/api/audit/verify",
)

def install(app):
    @app.before_request
    def _corr_and_freeze():
        cid = request.headers.get(CORR_HEADER_IN) or str(uuid.uuid4())
        g.correlation_id = cid

        if SC_FREEZE and request.method in ("POST","PUT","PATCH","DELETE"):
            path = request.path or ""
            if not path.startswith(FREEZE_ALLOWLIST_PREFIXES):
                raise SCError("MAINTENANCE_MODE", "System is in maintenance mode", status=503)

    @app.after_request
    def _headers(resp):
        cid = getattr(g, "correlation_id", None)
        if cid:
            resp.headers[CORR_HEADER_OUT] = cid
        resp.headers[VER_HEADER_OUT] = SC_VERSION
        return resp

    @app.errorhandler(Exception)
    def _handle(err):
        cid = getattr(g, "correlation_id", "-")
        payload, status = to_json(err, cid)
        return jsonify(payload), status
PY

cat > "$ROOT/sc_platform/health.py" <<'PY'
from flask import jsonify

def install(app):
    @app.get("/health")
    def health():
        return jsonify({"ok": True, "service": "sovereign-ui", "status": "healthy"})
PY

# ---------------- minimal /dash UI (no Node today) ----------------
cat > "$ROOT/ui/static/dash/index.html" <<'HTML'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Sovereign Dashboard (New)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial; padding: 20px; }
    .card { border: 1px solid #ddd; border-radius: 12px; padding: 16px; margin: 12px 0; }
    .muted { color: #666; }
    code { background: #f5f5f5; padding: 2px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <h1>🧠 Sovereign /dash (Zero-Break UI)</h1>
  <p class="muted">This is a safe drop-in UI layer. It does NOT change <code>/</code> or <code>/api/*</code>.</p>

  <div class="card">
    <h2>Status</h2>
    <pre id="status">Loading…</pre>
  </div>

  <div class="card">
    <h2>Controls</h2>
    <p>Headers:</p>
    <ul>
      <li><code>X-SC-Version</code></li>
      <li><code>X-Correlation-Id</code></li>
    </ul>
    <p class="muted">Freeze switch available via <code>SC_FREEZE=1</code> (blocks mutating methods).</p>
  </div>

  <div class="card">
    <h2>Next (Session 2)</h2>
    <ul>
      <li>React/Vite/TS + PWA</li>
      <li>Jobs / Approvals / Audit / Quotas pages</li>
      <li>WS live streams</li>
      <li>External gateway + search proxy with policies</li>
    </ul>
  </div>

  <script>
    async function fetchStatus() {
      const res = await fetch("/api/status", { headers: { "X-Client": "dash" } });
      const txt = await res.text();
      try {
        const data = JSON.parse(txt);
        document.getElementById("status").innerText = JSON.stringify(data, null, 2);
      } catch(e) {
        document.getElementById("status").innerText = txt;
      }
    }
    setInterval(fetchStatus, 1000);
    fetchStatus();
  </script>
</body>
</html>
HTML

# ---------------- patch ui/server.py safely (markers) ----------------
python3 - <<'PY'
import pathlib, re

ui = pathlib.Path.home()/"sovereign_core"/"ui"/"server.py"
txt = ui.read_text(errors="ignore")

if "SC_RELEASE_LOCK_BEGIN" in txt:
    print("✅ ui/server.py already patched (markers found).")
    raise SystemExit(0)

# Find first Flask app creation line
m = re.search(r'^\s*app\s*=\s*Flask\([^\n]*\)\s*$', txt, flags=re.M)
if not m:
    print("❌ لم أجد سطر app = Flask(...) داخل ui/server.py. عدّل يدويًا.")
    raise SystemExit(1)

insert = r'''
# --- SC_RELEASE_LOCK_BEGIN ---
from sc_platform.middleware import install as sc_install_mw
from sc_platform.health import install as sc_install_health
from sc_platform.flags import SC_NEW_UI
import os
from flask import send_from_directory

sc_install_mw(app)
sc_install_health(app)

# New UI served under /dash (Feature Flag: SC_NEW_UI=1)
_DASH_DIR = os.path.join(os.path.dirname(__file__), "static", "dash")

@app.get("/dash")
@app.get("/dash/")
@app.get("/dash/<path:path>")
def sc_dash(path="index.html"):
    if not SC_NEW_UI:
        return ("Not Found", 404)
    file_path = path if path else "index.html"
    full = os.path.join(_DASH_DIR, file_path)
    if os.path.exists(full):
        return send_from_directory(_DASH_DIR, file_path)
    return send_from_directory(_DASH_DIR, "index.html")
# --- SC_RELEASE_LOCK_END ---
'''.lstrip("\n")

# Insert right AFTER app = Flask(...)
pos = m.end()
newtxt = txt[:pos] + "\n" + insert + txt[pos:]

ui.write_text(newtxt)
print("✅ Patched ui/server.py (Release Lock + /health + /dash route).")
PY

# ---------------- docker prod package ----------------
cat > "$ROOT/infra/prod/entrypoint.sh" <<'SH'
#!/usr/bin/env bash
set -e
mkdir -p /app/logs
python3 /app/core/core.py > /app/logs/core.log 2>&1 &
exec python3 /app/ui/server.py
SH
chmod +x "$ROOT/infra/prod/entrypoint.sh"

cat > "$ROOT/infra/prod/Dockerfile" <<'DOCKER'
FROM python:3.12-slim
WORKDIR /app
COPY . /app

# optional requirements
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

EXPOSE 8080
CMD ["/app/infra/prod/entrypoint.sh"]
DOCKER

cat > "$ROOT/infra/prod/docker-compose.yml" <<'YML'
services:
  sovereign:
    build:
      context: ../..
      dockerfile: infra/prod/Dockerfile
    environment:
      - SC_VERSION=1
      - SC_FREEZE=0
      - SC_NEW_UI=0
    ports:
      - "8080:8080"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health').read(); print('ok')"]
      interval: 15s
      timeout: 5s
      retries: 10
YML

echo "✅ Patch Pack v1 installed."
echo ""
echo "Next steps:"
echo "1) Restart ui/server.py (same way you run it now)."
echo "2) Test:"
echo "   curl -i http://127.0.0.1:8080/health"
echo "3) Enable new UI:"
echo "   export SC_NEW_UI=1"
echo "   open: http://127.0.0.1:8080/dash"
echo ""
echo "Docker RC:"
echo "   docker compose -f $ROOT/infra/prod/docker-compose.yml up -d --build"
