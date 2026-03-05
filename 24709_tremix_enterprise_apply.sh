#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
TS="$(date +%Y%m%d_%H%M%S)"
BK="$HOME/tremix_master_backup_enterprise_${TS}.py"

if [ ! -f "$MASTER" ]; then
  echo "❌ tremix_master.py not found"
  exit 1
fi

cp -f "$MASTER" "$BK"
echo "🧷 Backup created: $BK"

python3 - <<'PY'
import os, re
path = os.path.expanduser("~/tremix_master.py")
src = open(path, "r", encoding="utf-8", errors="ignore").read()

ENTERPRISE_BLOCK = r'''
# ================= ENTERPRISE LAYER =================
import base64
from hashlib import sha256

TREMIX_SECRET = os.environ.get("TREMIX_SECRET", "default_dev_secret")

def _k():
    return sha256(TREMIX_SECRET.encode()).digest()

def encrypt_data(data: str) -> str:
    raw = data.encode()
    key = _k()
    enc = bytes([raw[i] ^ key[i % len(key)] for i in range(len(raw))])
    return base64.b64encode(enc).decode()

def decrypt_data(data: str) -> str:
    try:
        raw = base64.b64decode(data.encode())
        key = _k()
        dec = bytes([raw[i] ^ key[i % len(key)] for i in range(len(raw))])
        return dec.decode()
    except:
        return ""

def secure_save(path, obj):
    import json
    secure = encrypt_data(json.dumps(obj))
    with open(path, "w") as f:
        f.write(secure)

def secure_load(path, default):
    import json
    if not os.path.exists(path):
        return default
    raw = open(path).read()
    data = decrypt_data(raw)
    try:
        return json.loads(data)
    except:
        return default

# override sensitive loaders
def load_users(): return secure_load(USERS_FILE, {})
def save_users(u): secure_save(USERS_FILE, u)

def load_tokens(): return secure_load(TOKENS_FILE, {})
def save_tokens(t): secure_save(TOKENS_FILE, t)

def load_sessions(): return secure_load(SESSIONS_FILE, {})
def save_sessions(s): secure_save(SESSIONS_FILE, s)

def load_memory(): return secure_load(MEMORY_FILE, [])
def save_memory(m): secure_save(MEMORY_FILE, m)

# Health endpoint
@app.get("/health")
def health():
    return {
        "status": "ok",
        "services": len(load_registry()),
        "tasks": len(load_tasks()),
        "worker": worker_status(),
        "ai_backend": "ollama" if OLLAMA_HOST else ("openai" if OPENAI_API_KEY else "heuristic")
    }

# Metrics endpoint
@app.get("/metrics")
def metrics():
    import os, time
    return {
        "uptime": time.time(),
        "memory_size": os.path.getsize(MEMORY_FILE) if os.path.exists(MEMORY_FILE) else 0,
        "registry_size": os.path.getsize(REGISTRY_FILE) if os.path.exists(REGISTRY_FILE) else 0
    }
'''

if "ENTERPRISE LAYER" not in src:
    src += "\n\n" + ENTERPRISE_BLOCK

open(path, "w").write(src)
print("OK")
PY

echo "✅ Enterprise layer added."
echo "🔐 IMPORTANT:"
echo "  export TREMIX_SECRET='CHANGE_THIS_SECRET_NOW'"
echo ""
echo "🔁 Restart dashboard:"
echo "  pkill -f tremix_master.py"
echo "  python3 ~/tremix_master.py dashboard"
