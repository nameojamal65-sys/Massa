import json, requests
from security.signing import sign

class SCClient:
    def __init__(self, base_url="http://127.0.0.1:8080"):
        self.base_url = base_url.rstrip("/")
        self.token = None

    def login(self, user="admin", password="admin"):
        r = requests.post(self.base_url + "/api/login", json={"user": user, "password": password}, timeout=10)
        r.raise_for_status()
        j = r.json()
        if not j.get("ok"):
            raise RuntimeError("login_failed")
        self.token = j["token"]
        return self.token

    def command(self, command: str):
        if not self.token:
            raise RuntimeError("not_logged_in")
        payload = {"tenant": "default", "type": "unknown", "prompt": command}
        payload_str = json.dumps({"tenant":"default","type":"unknown","prompt":command}, ensure_ascii=False, sort_keys=True)
        sig = sign(payload_str)
        r = requests.post(self.base_url + "/api/command", json={"command": command, "token": self.token, "signature": sig}, timeout=30)
        r.raise_for_status()
        return r.json()
