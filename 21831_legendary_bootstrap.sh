#!/bin/bash

echo "🚀 Initializing Legendary Global Platform..."

BASE_DIR=~/Legendary_Dashboard
cd $BASE_DIR || exit

echo "📦 Creating professional structure..."
mkdir -p legendary/{core,agents,orchestrator,control,api,plugins,utils}

touch legendary/__init__.py
touch legendary/core/__init__.py
touch legendary/agents/__init__.py
touch legendary/orchestrator/__init__.py
touch legendary/control/__init__.py
touch legendary/api/__init__.py
touch legendary/plugins/__init__.py
touch legendary/utils/__init__.py

echo "🧠 Creating BaseAgent..."
cat > legendary/core/base_agent.py <<EOF
import threading
import time

class BaseAgent:
    def __init__(self, name):
        self.name = name
        self._running = False
        self._thread = None

    def run(self):
        while self._running:
            time.sleep(1)

    def start(self):
        if not self._running:
            self._running = True
            self._thread = threading.Thread(target=self.run)
            self._thread.start()

    def stop(self):
        self._running = False
        if self._thread:
            self._thread.join()

    def status(self):
        return "running" if self._running else "stopped"
EOF

echo "🎛 Creating Orchestrator..."
cat > legendary/orchestrator/orchestrator.py <<EOF
class Orchestrator:
    def __init__(self):
        self.agents = {}

    def register(self, agent):
        self.agents[agent.name] = agent

    def start(self, name):
        if name in self.agents:
            self.agents[name].start()

    def stop(self, name):
        if name in self.agents:
            self.agents[name].stop()

    def list_agents(self):
        return {
            name: agent.status()
            for name, agent in self.agents.items()
        }
EOF

echo "🤖 Creating Sample Agent..."
cat > legendary/agents/sample_agent.py <<EOF
import time
from legendary.core.base_agent import BaseAgent

class SampleAgent(BaseAgent):
    def run(self):
        while self._running:
            print(f"🔥 {self.name} working...")
            time.sleep(3)
EOF

echo "🌐 Creating API Server..."
cat > legendary/api/server.py <<EOF
from fastapi import FastAPI
from legendary.orchestrator.orchestrator import Orchestrator
from legendary.agents.sample_agent import SampleAgent

app = FastAPI(title="Legendary Global AI Platform")

orchestrator = Orchestrator()
agent = SampleAgent("agent_1")
orchestrator.register(agent)

@app.get("/health")
def health():
    return {"status": "Legendary running"}

@app.get("/agents")
def list_agents():
    return orchestrator.list_agents()

@app.post("/agents/{name}/start")
def start_agent(name: str):
    orchestrator.start(name)
    return {"status": "started"}

@app.post("/agents/{name}/stop")
def stop_agent(name: str):
    orchestrator.stop(name)
    return {"status": "stopped"}
EOF

echo "🚀 Creating app entry..."
cat > app.py <<EOF
import uvicorn

if __name__ == "__main__":
    uvicorn.run("legendary.api.server:app", host="0.0.0.0", port=8000)
EOF

echo "📜 Creating CLI..."
cat > cli.py <<EOF
import sys
from legendary.orchestrator.orchestrator import Orchestrator
from legendary.agents.sample_agent import SampleAgent

orchestrator = Orchestrator()
agent = SampleAgent("agent_cli")
orchestrator.register(agent)

if len(sys.argv) < 2:
    print("Usage: python3 cli.py [start|stop|status]")
    sys.exit(1)

cmd = sys.argv[1]

if cmd == "start":
    orchestrator.start("agent_cli")
    print("Agent started")
elif cmd == "stop":
    orchestrator.stop("agent_cli")
    print("Agent stopped")
elif cmd == "status":
    print(orchestrator.list_agents())
EOF

echo "🛰 Creating daemon..."
cat > daemon.sh <<EOF
#!/bin/bash
nohup python3 app.py > legendary.log 2>&1 &
echo \$! > legendary.pid
echo "✅ Legendary running in background"
EOF

chmod +x daemon.sh

echo "📦 Installing dependencies..."
pip install fastapi uvicorn --break-system-packages 2>/dev/null

echo "🏁 Legendary Global Platform Ready!"
echo ""
echo "▶️ Run normally:"
echo "python3 app.py"
echo ""
echo "🛰 Run as daemon:"
echo "./daemon.sh"
echo ""
echo "🛑 Stop daemon:"
echo "kill \$(cat legendary.pid)"
