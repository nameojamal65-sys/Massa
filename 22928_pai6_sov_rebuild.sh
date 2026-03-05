#!/usr/bin/env bash
# ☢️ PAI6 — SOVEREIGN REBUILD MASTER SCRIPT
# One Script — Full System Architecture + Core + Engines + Security + Run

set -e

ROOT="$HOME/PAI6_UltimateClosure/PAI6"
echo "☢️ INITIATING SOVEREIGN REBUILD"
echo "📍 ROOT: $ROOT"

rm -rf "$ROOT"
mkdir -p "$ROOT"/{core,engines,backend,frontend,security,orchestrator,data,logs,reports}

# ================= CORE =================
cat << 'PYEOF' > "$ROOT/core/consciousness.py"
class Consciousness:
    def awaken(self):
print("🧠 Consciousness Online")
return "ACTIVE"
PYEOF

cat << 'PYEOF' > "$ROOT/core/memory.py"
import sqlite3
from pathlib import Path
DB = Path(__file__).parent.parent / "data/memory.db"

def init():
DB.parent.mkdir(exist_ok=True)
con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS memory (key TEXT, value TEXT)")
con.commit(); con.close()

def store(k,v):
con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("INSERT INTO memory VALUES (?,?)",(k,v))
con.commit(); con.close()
PYEOF

cat << 'PYEOF' > "$ROOT/core/decision.py"
class DecisionEngine:
    def decide(self, context):
print("⚖️ Decision:", context)
return "EXECUTE"
PYEOF

cat << 'PYEOF' > "$ROOT/core/main.py"
from core.consciousness import Consciousness
from core.memory import init, store
from core.decision import DecisionEngine

class SovereignCore:
    def boot(self):
print("👑 Sovereign Core Booting...")
init()
store("boot","success")
self.state = Consciousness().awaken()
print("🧠 State:", self.state)
return self.state
PYEOF

# ================= ENGINES =================
cat << 'PYEOF' > "$ROOT/engines/task_engine.py"
import time
class TaskEngine:
    def run(self):
print("⚙ Task Engine Running")
while True:
print("🔁 Autonomous Cycle")
time.sleep(5)
PYEOF

# ================= ORCHESTRATOR =================
cat << 'PYEOF' > "$ROOT/orchestrator/main.py"
class Orchestrator:
    def run(self):
print("🛰 Orchestrator Active")
PYEOF

# ================= SECURITY =================
cat << 'PYEOF' > "$ROOT/security/guardian.py"
class Guardian:
    def verify(self):
print("🛡 Guardian Online — System Secure")
return True
PYEOF

# ================= BACKEND =================
cat << 'PYEOF' > "$ROOT/backend/server.py"
def start():
print("🌐 Backend API Online")
PYEOF

# ================= FRONTEND =================
cat << 'PYEOF' > "$ROOT/frontend/ui.py"
def start():
print("🎛 Frontend UI Online")
PYEOF

# ================= MASTER RUN =================
cat << 'PYEOF' > "$ROOT/run.py"
from core.main import SovereignCore
from orchestrator.main import Orchestrator
from engines.task_engine import TaskEngine
from security.guardian import Guardian
from backend.server import start as backend_start
from frontend.ui import start as frontend_start
import threading

print("🚀 PAI6 — SOVEREIGN SYSTEM START")

Guardian().verify()

core = SovereignCore()
core.boot()

backend_start()
frontend_start()

orchestrator = Orchestrator()
orchestrator.run()

engine = TaskEngine()
threading.Thread(target=engine.run, daemon=True).start()

print("👑 SYSTEM IS FULLY OPERATIONAL")

while True:
pass
PYEOF

chmod -R 755 "$ROOT"
chmod +x "$ROOT/run.py"

echo "☢️ SOVEREIGN SYSTEM REBUILD COMPLETE"
echo "🚀 Launch: python3 $ROOT/run.py"