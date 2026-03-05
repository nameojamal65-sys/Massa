#!/usr/bin/env bash
set -e

echo "☢️ Sovereign Nuclear Fix & Rebuild..."

BASE=~/sovereign-core
rm -rf $BASE
mkdir -p $BASE/{core,orchestrator,intelligence/multi_lus,intelligence/router,memory,doctor,dashboard,logs,tmp}

pkg install -y python git curl wget clang make openssl-tool
pip install --upgrade pip
pip install fastapi uvicorn psutil rich aiohttp websockets pydantic

echo "🧠 AI Router..."
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

echo "🌍 Multi-Lingual Router..."
cat > $BASE/intelligence/multi_lus/multi_lus_router.py << 'PY'
from intelligence.router.router import AIRouter

class MultiLingualRouter(AIRouter):
    def route_multilang(self, session_id, task, lang="en"):
        data = self.route(session_id, task)
        data["language"] = lang
        return data
PY

echo "🧬 Memory Core..."
cat > $BASE/memory/memory_core.py << 'PY'
import json, time

class MemoryCore:
    def __init__(self, path="memory.db"):
        self.path = path

    def write(self, key, value):
        try:
            data = json.load(open(self.path))
        except:
            data = {}
        data[key] = {"value": value, "ts": time.time()}
        json.dump(data, open(self.path,"w"))

    def read(self, key):
        try:
            return json.load(open(self.path)).get(key)
        except:
            return None
PY

echo "🩺 System Doctor..."
cat > $BASE/doctor/system_doctor.py << 'PY'
import psutil

def health():
    return {
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage('/').percent,
        "status": "OK"
    }
PY

echo "🎛 Orchestrator..."
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

echo "🌐 Dashboard API..."
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

echo "🚀 Boot Launcher..."
cat > $BASE/boot.sh << 'SH'
#!/usr/bin/env bash
cd ~/sovereign-core
export PYTHONPATH=$PWD
uvicorn dashboard.app:app --host 0.0.0.0 --port 8080
SH

chmod +x $BASE/boot.sh

echo "🔥 Sovereign Core Rebuilt Successfully"
echo "🚀 Launch using:"
echo "   bash ~/sovereign-core/boot.sh"
