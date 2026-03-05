import requests
from core.config import Settings


class ClusterManager:
    def __init__(self):
        self.nodes = {}

    def register(self, name: str, url: str):
        self.nodes[name] = url

    def dispatch(self, task_type: str, payload: dict):
        if not self.nodes:
            return {"error": "no_nodes"}
        for name, url in self.nodes.items():
            try:
                kwargs = {"timeout": 10}
                if Settings.MTLS:
                    kwargs["verify"] = Settings.CA_CERT
                    kwargs["cert"] = (
                        Settings.CLIENT_CERT, Settings.CLIENT_KEY)
                r = requests.post(
                    f"{url}/execute",
                    json={
                        "type": task_type,
                        "payload": payload},
                    **kwargs)
                if r.status_code == 200:
                    out = r.json()
                    out["_node"] = name
                    return out
            except Exception:
                continue
        return {"error": "no_available_node"}
