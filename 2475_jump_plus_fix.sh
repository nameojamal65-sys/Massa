#!/usr/bin/env bash
set -e

echo "☢️  PAI6 — SOVEREIGN JUMP+ FIXED ACTIVATION"
echo "=========================================="

ROOT="$HOME/pai6_sovereign_core"
cd "$ROOT" || exit 1

pip install cryptography websockets fastapi uvicorn rich psutil >/dev/null 2>&1

# Create structure safely
mkdir -p sovereign decision override api ai logs

# ========== DECISION ENGINE ==========
cat > decision/engine.py << 'PY'
import time

class DecisionEngine:
    def __init__(self):
        self.state="ACTIVE"

    def decide(self, context):
        c=context.lower()
        if "threat" in c:
            return "DEFENSIVE_PROTOCOL"
        if "optimize" in c:
            return "OPTIMIZATION_PROTOCOL"
        if "expand" in c:
            return "EXPANSION_PROTOCOL"
        return "STANDARD_OPERATION"

if __name__=="__main__":
    eng=DecisionEngine()
    while True:
        print("🧠 Decision Engine:", eng.decide("optimize system"))
        time.sleep(3)
PY

# ========== REMOTE OVERRIDE ==========
cat > override/remote_override.py << 'PY'
import hashlib,time

class RemoteOverride:
    def __init__(self):
        self.master = hashlib.sha256(f"SOVEREIGN::{time.time()}".encode()).hexdigest()

    def verify(self,key):
        return key==self.master

    def get_key(self):
        return self.master
PY

# ========== AUTONOMOUS CORE ==========
cat > sovereign/autonomous_core.py << 'PY'
import time
from decision.engine import DecisionEngine

class AutonomousCore:
    def __init__(self):
        self.engine=DecisionEngine()
        self.state="ACTIVE"

    def run(self):
        while True:
            action=self.engine.decide("optimize operations")
            print("⚙️ Autonomous Core:",action)
            time.sleep(2)

if __name__=="__main__":
    core=AutonomousCore()
    core.run()
PY

# ========== COMMAND CENTER API ==========
cat > api/command_center.py << 'PY'
from fastapi import FastAPI
from sovereign.autonomous_core import AutonomousCore
from override.remote_override import RemoteOverride
from decision.engine import DecisionEngine

app=FastAPI()

core=AutonomousCore()
override=RemoteOverride()
engine=DecisionEngine()

@app.get("/status")
def status():
    return {"state":"SOVEREIGN_ACTIVE"}

@app.get("/decision")
def decision(context:str="optimize"):
    return {"decision":engine.decide(context)}

@app.get("/override_key")
def key():
    return {"MASTER_KEY":override.get_key()}

@app.post("/override")
def override_cmd(key:str):
    if override.verify(key):
        return {"override":"GRANTED"}
    return {"override":"DENIED"}
PY

# ========== RUNNER ==========
cat > run_plus.sh << 'EOF2'
#!/usr/bin/env bash
echo "🚀 Launching PAI6 Sovereign Jump+"
uvicorn api.command_center:app --host 0.0.0.0 --port 9090
EOF2

chmod +x run_plus.sh

echo ""
echo "☢️ SOVEREIGN JUMP+ FIX COMPLETE"
echo "================================"
echo "🚀 Launch:       ./run_plus.sh"
echo "🌐 Command API:  http://127.0.0.1:9090/status"
echo "🧠 Decisions:    http://127.0.0.1:9090/decision"
echo "🔐 Override Key: http://127.0.0.1:9090/override_key"
echo ""
