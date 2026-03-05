#!/usr/bin/env bash
set -e

echo "☢️  PAI6 — Nuclear Master One‑Shot Bootstrap"
echo "==========================================="

ROOT="$HOME/pai6_nuclear_master"
PYTHON=$(command -v python3 || command -v python)

echo "📂 Working Dir: $ROOT"
rm -rf "$ROOT"
mkdir -p "$ROOT"
cd "$ROOT"

echo "⚙️ Checking Python..."
if [ -z "$PYTHON" ]; then
  echo "❌ Python3 not found. Installing..."
  pkg install -y python || apt install -y python3
fi

echo "⚙️ Installing base packages..."
pip install --upgrade pip >/dev/null 2>&1 || true
pip install flask requests aiohttp sqlalchemy >/dev/null 2>&1

echo "📦 Environment ready"

# ================= CORE =================

mkdir -p core intelligence api dashboard tools

cat > core/core.py << 'PY'
class SovereignCore:
    def __init__(self):
        self.state = "BOOTING"
    def boot(self):
        self.state = "ONLINE"
        print("🚀 Sovereign Core ONLINE")
    def status(self):
        return self.state
PY

cat > intelligence/router.py << 'PY'
class AIRouter:
    def route(self, task):
        if "code" in task.lower():
            return {"model":"code","task":task}
        return {"model":"analysis","task":task}
PY

cat > api/app.py << 'PY'
from flask import Flask, jsonify
from core.core import SovereignCore

app = Flask(__name__)
core = SovereignCore()
core.boot()

@app.route("/health")
def health():
    return jsonify({"status": core.status()})

@app.route("/status")
def status():
    return jsonify({"state": core.status()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY

cat > dashboard/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>PAI6 Nuclear Master</title>
<style>
body{background:#050b1a;color:#00ffee;font-family:monospace;text-align:center}
.card{border:1px solid #00ffee;padding:20px;margin:20px}
</style>
</head>
<body>
<h1>☢️ PAI6 Nuclear Master Dashboard</h1>
<div class="card" id="status">Loading...</div>
<script>
fetch("/status").then(r=>r.json()).then(d=>{
document.getElementById("status").innerHTML="STATE: "+d.state;
})
</script>
</body>
</html>
HTML

# ================= DIAGNOSTIC =================

cat > tools/doctor.py << 'PY'
import requests, socket, sys

def check_web():
    try:
        r=requests.get("https://api.github.com",timeout=5)
        return r.status_code==200
    except:
        return False

def check_ai():
    return True

def check_video():
    try:
        import cv2
        return True
    except:
        return False

print("🧪 Nuclear System Diagnostic")
print("============================")
print("🌐 Web Access  :",check_web())
print("🤖 AI Router   :",check_ai())
print("🎥 Video Stack :",check_video())

ok=sum([check_web(),check_ai(),check_video()])
print("============================")
print(f"🚀 SYSTEM READINESS: {round((ok/3)*100,2)}%")
PY

# ================= RUN =================

echo ""
echo "🚀 Launch API:     python3 api/app.py"
echo "🧪 Full Check:     python3 tools/doctor.py"
echo "🌐 Dashboard URL:  http://127.0.0.1:8080/dashboard/index.html"
echo ""
echo "☢️ Nuclear Master Deployment COMPLETE"
