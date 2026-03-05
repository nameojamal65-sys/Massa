class TaskDispatcher:
    def dispatch(self, task):
        print(f"🧠 Dispatching: {task}")
        return {"status":"ok","payload":task}
