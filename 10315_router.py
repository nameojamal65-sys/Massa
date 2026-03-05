class AIRouter:
    def route(self, session, task):
        if "code" in task.lower():
            return {"model":"code","task":task}
        return {"model":"analysis","task":task}
