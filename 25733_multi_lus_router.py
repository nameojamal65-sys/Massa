from intelligence.router.router import AIRouter


class MultiLingualRouter(AIRouter):
    def route_multilang(self, session_id, task, lang="en"):
        data = self.route(session_id, task)
        data["language"] = lang
        return data
