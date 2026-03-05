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