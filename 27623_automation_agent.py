import subprocess
from core.config import Settings
from core.logger import log

class AutomationAgent:
    def run(self, cmd: str):
        cmd = cmd or ""
        if not Settings.ALLOW_EXTERNAL and ("curl" in cmd or "wget" in cmd):
            return {"status":"blocked","reason":"external disabled by policy"}
        log(f"AutomationAgent: {cmd}")
        p = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return {"returncode":p.returncode,"stdout":p.stdout,"stderr":p.stderr}
