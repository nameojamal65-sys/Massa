#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
TS="$(date +%Y%m%d_%H%M%S)"
BK="$HOME/tremix_master_backup_before_lock_${TS}.py"

if [ ! -f "$MASTER" ]; then
  echo "❌ ما لقيت: $MASTER"
  exit 1
fi

echo "🧷 Backup -> $BK"
cp -f "$MASTER" "$BK"

python3 - <<'PY'
import os, re

path = os.path.expanduser("~/tremix_master.py")
src = open(path, "r", encoding="utf-8", errors="ignore").read()

SESSION_TIMEOUT_BLOCK = r'''
# ---------------- Session expiry (HARDENED) ----------------
SESSION_TIMEOUT_SEC = 3600  # 1 hour

def is_session_valid(token: str):
    sessions = load_sessions()
    s = sessions.get(token)
    if not s:
        return False
    try:
        created = datetime.fromisoformat(s.get("created_at"))
    except Exception:
        return False
    if (datetime.now() - created).total_seconds() > SESSION_TIMEOUT_SEC:
        # expire
        sessions.pop(token, None)
        save_sessions(sessions)
        return False
    return True

def cleanup_old_sessions():
    sessions = load_sessions()
    changed = False
    for token, s in list(sessions.items()):
        try:
            created = datetime.fromisoformat(s.get("created_at"))
        except Exception:
            sessions.pop(token, None)
            changed = True
            continue
        if (datetime.now() - created).total_seconds() > SESSION_TIMEOUT_SEC:
            sessions.pop(token, None)
            changed = True
    if changed:
        save_sessions(sessions)
'''

# Inject session block near top after auth utils
if "SESSION_TIMEOUT_SEC" not in src:
    marker = re.search(r'(def\s+get_current_user.*?\n)', src, flags=re.S)
    if marker:
        i = marker.end()
        src = src[:i] + "\n" + SESSION_TIMEOUT_BLOCK + "\n" + src[i:]
    else:
        src += "\n\n" + SESSION_TIMEOUT_BLOCK

# Modify get_current_user to enforce expiry
src = re.sub(
    r'def\s+get_current_user\s*\(request: Request\).*?\n(?:\s+.*\n)+?',
    '''def get_current_user(request: Request) -> Optional[Dict[str, Any]]:
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
''',
    src,
    flags=re.S
)

# Enforce localhost-only dashboard
LOCALHOST_CHECK = r'''
# ---- Localhost-only dashboard protection ----
def enforce_localhost(request: Request):
    try:
        ip = (request.client.host or "").strip()
    except Exception:
        ip = ""
    if ip not in ("127.0.0.1", "::1"):
        raise PermissionError("dashboard_localhost_only")
'''

if "dashboard_localhost_only" not in src:
    src = LOCALHOST_CHECK + "\n" + src

# Inject enforce_localhost into dashboard route
src = re.sub(
    r'@app\.get\("/", response_class=HTMLResponse\)\ndef dashboard\(request: Request\):',
    '''@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request):
    enforce_localhost(request)
''',
    src
)

# Force uvicorn bind to 127.0.0.1
src = src.replace('host="0.0.0.0"', 'host="127.0.0.1"')
src = src.replace("host='0.0.0.0'", "host='127.0.0.1'")

open(path, "w", encoding="utf-8").write(src)
print("OK")
PY

echo "✅ Dashboard locked to localhost."
echo "✅ Sessions expire after 1 hour."
echo "🔁 أعد التشغيل:"
echo "  pkill -f 'tremix_master.py.*dashboard' 2>/dev/null || true"
echo "  python3 ~/tremix_master.py dashboard"
