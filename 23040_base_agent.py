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
