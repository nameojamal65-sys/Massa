import time
from legendary.core.base_agent import BaseAgent

class SampleAgent(BaseAgent):
    def run(self):
        while self._running:
            print(f"🔥 {self.name} working...")
            time.sleep(3)
