import uuid, time, threading

class TaskManager:
    def __init__(self):
        self._lock = threading.Lock()
        self.tasks = {}

    def create(self, payload: dict):
        tid = str(uuid.uuid4())
        with self._lock:
            self.tasks[tid] = {
                "id": tid,
                "created_at": time.time(),
                "status": "queued",
                "payload": payload,
                "result": None,
                "error": None
            }
        return tid

    def update(self, tid: str, **fields):
        with self._lock:
            if tid in self.tasks:
                self.tasks[tid].update(fields)

    def get(self, tid: str):
        with self._lock:
            return self.tasks.get(tid)

    def list(self):
        with self._lock:
            return dict(self.tasks)
