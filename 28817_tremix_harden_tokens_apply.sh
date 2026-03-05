#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
TS="$(date +%Y%m%d_%H%M%S)"
BK="$HOME/tremix_master_backup_before_token_harden_${TS}.py"

if [ ! -f "$MASTER" ]; then
  echo "❌ ما لقيت: $MASTER"
  exit 1
fi

echo "🧷 Backup -> $BK"
cp -f "$MASTER" "$BK"

python3 - <<'PY'
import re, os, sys

path = os.path.expanduser("~/tremix_master.py")
src = open(path, "r", encoding="utf-8", errors="ignore").read()

TOKEN_BLOCK = r'''
# ---------------- API tokens (HARDENED: store hash only) ----------------
def load_tokens(): return load_json(TOKENS_FILE, {})
def save_tokens(t): save_json(TOKENS_FILE, t)

def token_hash(token: str) -> str:
    return sha256(token)

def create_api_token(username: str, label: str = "") -> str:
    """
    Returns the *raw* token ONCE. Stored form is sha256(token) only.
    """
    tokens = load_tokens()
    raw = secrets.token_urlsafe(36)
    h = token_hash(raw)
    tokens[h] = {
        "user": username,
        "label": label,
        "created_at": datetime.now().isoformat(),
        "revoked": False
    }
    save_tokens(tokens)
    return raw

def revoke_api_token(raw_token: str) -> bool:
    tokens = load_tokens()
    h = token_hash(raw_token)
    if h in tokens:
        tokens[h]["revoked"] = True
        tokens[h]["revoked_at"] = datetime.now().isoformat()
        save_tokens(tokens)
        return True
    return False

def auth_api_token(x_api_token: Optional[str]) -> Optional[Dict[str, Any]]:
    if not x_api_token:
        return None
    tokens = load_tokens()
    h = token_hash(x_api_token)
    t = tokens.get(h)
    if not t or t.get("revoked"):
        return None
    users = load_users()
    u = users.get(t["user"])
    if not u:
        return None
    return {
        "username": t["user"],
        "role": u.get("role", "viewer"),
        "token_hash": h,
        "label": t.get("label", "")
    }
'''

REQUIRE_API_BLOCK = r'''
def require_api(request: Request, x_api_token: Optional[str]) -> Tuple[Dict[str, Any], Optional[JSONResponse]]:
    # Localhost-only API
    try:
        ip = (request.client.host or "").strip()
    except Exception:
        ip = ""
    if ip not in ("127.0.0.1", "::1"):
        return {}, JSONResponse({"ok": False, "error": "api_localhost_only"}, status_code=403)

    au = auth_api_token(x_api_token)
    if not au:
        return {}, JSONResponse({"ok": False, "error": "unauthorized"}, status_code=401)

    # rate-limit bucket uses token_hash
    token_key = au.get("token_hash", "unknown")
    rl = rate_limit_or_429(token_key)
    if rl:
        return au, rl
    return au, None
'''

# 1) Replace token section if exists (best effort)
patterns = [
    r'(#\s*-+\s*API tokens.*?\n)(.*?)(\n#\s*-+\s*service engine|\n#\s*-+\s*services|\n#\s*-+\s*dashboard|\n#\s*-+\s*memory)',
    r'(#\s*-+\s*API tokens.*?\n)(.*?)(\n#\s*-+\s*service|\n#\s*-+\s*services)'
]

replaced = False
for pat in patterns:
    m = re.search(pat, src, flags=re.S)
    if m:
        src = src[:m.start(1)] + TOKEN_BLOCK.strip("\n") + "\n\n" + src[m.start(3):]
        replaced = True
        break

if not replaced:
    # If no section found, append near top after imports/config (best effort)
    insert_after = re.search(r'(RL_MAX_REQ\s*=\s*[0-9]+\s*\n.*?\n)', src, flags=re.S)
    if insert_after:
        i = insert_after.end(1)
        src = src[:i] + "\n" + TOKEN_BLOCK.strip("\n") + "\n\n" + src[i:]
        replaced = True

# 2) Replace require_api function (must have Request in signature in Patch4+)
m = re.search(r'def\s+require_api\s*\(.*?\)\s*->\s*Tuple\[.*?\]:\n(?:\s+.*\n)+?\n', src, flags=re.S)
if m:
    src = src[:m.start()] + REQUIRE_API_BLOCK.strip("\n") + "\n\n" + src[m.end():]
else:
    # if not found, append it (rare)
    src += "\n\n" + REQUIRE_API_BLOCK.strip("\n") + "\n"

# 3) Update admin token UI create endpoint to show token ONCE (if exists)
# replace any token create response that shows token variable named tk/raw
src = re.sub(
    r'return\s+HTMLResponse\(f"<h3>✅\s*Token\s*Created</h3><p><code>\{.*?\}</code></p><p><a href=.*?</a></p>"\)',
    'return HTMLResponse(f"<h3>✅ Token Created (SHOW ONCE)</h3><p><code>{tk}</code></p><p>انسخه الآن — لن نعرضه مرة ثانية.</p><p><a href=\'/\'>Back</a></p>")',
    src,
    flags=re.S
)

# 4) Update token table display (avoid showing raw token; show hash prefix)
# best effort: replace {tk[:10]}… with hash prefix display label
src = src.replace("{tk[:10]}…", "{tk[:12]}…")  # if tk is hash now in loop, ok

open(path, "w", encoding="utf-8").write(src)
print("OK")
PY

echo "✅ Token hardening applied."
echo "🔁 شغّل الواجهة من جديد:"
echo "  pkill -f 'tremix_master.py.*dashboard' 2>/dev/null || true"
echo "  python3 ~/tremix_master.py dashboard"
