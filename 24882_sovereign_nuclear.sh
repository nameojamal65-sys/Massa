#!/usr/bin/env bash
set -e

echo "☢️ Sovereign Nuclear Installer Starting..."

BASE=~/sovereign-core
mkdir -p $BASE/{core,orchestrator,intelligence,memory,doctor,dashboard,logs,tmp}

echo "📦 Installing dependencies..."
pkg install -y python git curl wget clang make openssl-tool

pip install --upgrade pip
pip install fastapi uvicorn psutil rich aiohttp websockets pydantic

echo "🧠 Building AI Router..."
mkdir -p $BASE/intelligence/router
cat > $BASE/intelligence/router/router.py << 'PY'
class AIRouter:
    def __init__(self):
        self.models = {}

    def register_model(self, name, meta):
        self.models[name] = meta

    def route(self, session_id, task):
        return {
            "session": session_id,
            "task": task,
            "models": list(self.models.keys()),
            "status": "routed"
        }
PY

echo "🌍 Building Multilingual Intelligence Layer..."
mkdir -p $BASE/intelligence/multi_lus
cat > $BASE/intelligence/multi_lus/multi_lus_router.py << 'PY'
from intelligence.router.router import AIRouter

class MultiLingualRouter(AIRouter):
    def __init__(self):
        super().__init__()

    def route_multilang(self, session_id, task, lang="en"):
        data = self.route(session_id, task)
        data["language"] = lang
        return data
PY

echo "🧬 Building Memory Core..."
mkdir -p $BASE/memory
cat > $BASE/memory/memory_core.py << 'PY'
import json, time

class MemoryCore:
    def __init__(self, path="memory.db"):
        self.path = path

    def write(self, key, value):
        data = {}
        try:
            data = json.load(open(self.path))
        except:
            pass
        data[key] = {"value": value, "ts": time.time()}
        json.dump(data, open(self.path,"w"))

    def read(self, key):
        try:
            return json.load(open(self.path)).get(key)
        except:
            return None
PY

echo "🩺 Building System Doctor..."
mkdir -p $BASE/doctor
cat > $BASE/doctor/system_doctor.py << 'PY'
import os, psutil, time

def health():
    return {
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage('/').percent,
        "status": "OK"
    }

if __name__ == "__main__":
    while True:
        print("🩺 Health:", health())
        time.sleep(5)
PY

echo "🎛 Building Orchestrator..."
mkdir -p $BASE/orchestrator
cat > $BASE/orchestrator/orchestrator.py << 'PY'
from intelligence.multi_lus.multi_lus_router import MultiLingualRouter
from memory.memory_core import MemoryCore

router = MultiLingualRouter()
memory = MemoryCore()

router.register_model("analysis",{"type":"llm"})
router.register_model("code",{"type":"llm"})
router.register_model("vision",{"type":"multimodal"})

def execute(task, lang="en"):
    routed = router.route_multilang("sovereign",task,lang)
    memory.write(task,routed)
    return routed
PY

echo "🌐 Building Dashboard API..."
mkdir -p $BASE/dashboard
cat > $BASE/dashboard/app.py << 'PY'
from fastapi import FastAPI
from orchestrator.orchestrator import execute
from doctor.system_doctor import health

app = FastAPI()

@app.get("/")
def root():
    return {"status":"Sovereign Core Online"}

@app.get("/health")
def h():
    return health()

@app.post("/run")
def run(task:str, lang:str="en"):
    return execute(task,lang)
PY

echo "🚀 Building Boot Launcher..."
cat > $BASE/boot.sh << 'SH'
#!/usr/bin/env bash
cd ~/sovereign-core
export PYTHONPATH=$PWD
uvicorn dashboard.app:app --host 0.0.0.0 --port 8080
SH

chmod +x $BASE/boot.sh

echo "🔥 Nuclear Core Installed Successfully"
echo "🚀 Start system using:"
echo "   bash ~/sovereign-core/boot.sh"
