import threading,time,os,sys

class SovereignCore:
    def __init__(self):
self.modules=[]
self.running=True

    def load(self):
print("🧠 Loading Autonomous Intelligence Layers...")
self.modules=[
"Decision Engine",
"Execution Engine",
"Self Governance",
"Security Core",
"Control Layer"
]
for m in self.modules:
print(f"⚙️  {m} Loaded")

    def run(self):
print("👑 Sovereign Core Active — Autonomous Mode")
while self.running:
time.sleep(5)
print("🫀 System Pulse — Stable")

core = SovereignCore()
core.load()
core.run()