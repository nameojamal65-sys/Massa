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
