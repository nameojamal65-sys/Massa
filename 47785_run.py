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