#!/data/data/com.termux/files/usr/bin/bash

clear
echo "☢️  SOVEREIGN CORE NUCLEUS"
echo "=========================="
echo "🔥 MODE: SOVEREIGN ACTIVATION"
echo ""

PASS=true
PORT=9200

log(){ echo -e "⚙️  $1"; }
ok(){ echo -e "   ✅ $1"; }
fail(){ echo -e "   ❌ $1"; PASS=false; }

# -------- Base --------
log "System validation..."
uname -a >/dev/null && ok "Kernel OK" || fail "Kernel FAIL"
df -h >/dev/null && ok "Storage OK" || fail "Storage FAIL"

# -------- Python --------
log "Python core..."
python - << 'PY'
import sys
print("   ✅ Python:",sys.version.split()[0])
PY

# -------- Network --------
log "Network..."
ping -c 1 google.com >/dev/null 2>&1 && ok "Internet OK" || fail "Internet FAIL"

# -------- Control API --------
log "Starting Sovereign Control API..."

cat > sovereign_control_api.py << 'PY'
from fastapi import FastAPI
import uvicorn, socket, time

app = FastAPI(title="Sovereign Control Core")

@app.get("/")
def root():
    return {
        "status":"ONLINE",
        "node":"SOVEREIGN_PHONE",
        "time":time.ctime(),
        "ip":socket.gethostbyname(socket.gethostname())
    }

@app.get("/ping")
def ping():
    return {"pong":"ok"}

if __name__=="__main__":
    uvicorn.run(app, host="0.0.0.0", port=9200)
PY

pip install fastapi uvicorn >/dev/null 2>&1

python sovereign_control_api.py >/dev/null 2>&1 &
sleep 2

curl -s http://127.0.0.1:$PORT >/dev/null && ok "Control API ONLINE" || fail "Control API FAIL"

# -------- Final --------
echo ""
echo "=============================="
if [ "$PASS" = true ]; then
  echo "🟢 SOVEREIGN CORE ACTIVE"
  echo "🌐 Control API: http://127.0.0.1:$PORT"
else
  echo "🔴 CORE PARTIAL"
fi
echo "=============================="
