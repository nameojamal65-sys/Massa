from intelligence.ai_router.router import AIRouter
from intelligence.multi_lus.translator import Translator

class MultiLingualRouter(AIRouter):
    def __init__(self):
        super().__init__()
        self.translator = Translator()
    def route_multilang(self, session, task, lang="en"):
        routed = self.route(session, task)
        routed["language"] = lang
        routed["translated"] = self.translator.translate(task, lang)
        return routed
