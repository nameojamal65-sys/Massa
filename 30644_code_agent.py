import os, subprocess
from core.logger import log

class CodeAgent:
    def __init__(self):
        self.use_ollama = os.getenv("SC_USE_OLLAMA","0") == "1"
        self.model = os.getenv("SC_OLLAMA_MODEL","codellama")

    def _ollama_ok(self):
        try:
            subprocess.check_output(["ollama","--version"], stderr=subprocess.STDOUT, text=True)
            return True
        except Exception:
            return False

    def generate(self, prompt: str):
        prompt = prompt or "Generate code"
        if self.use_ollama and self._ollama_ok():
            log("CodeAgent: using ollama")
            out = subprocess.check_output(["ollama","run",self.model,prompt], stderr=subprocess.STDOUT, text=True)
            return {"engine":"ollama","code":out,"model":self.model}

        code = f'''# Generated code (template)\n\nfrom flask import Flask\n\napp = Flask(__name__)\n\n@app.get("/health")\ndef health():\n    return {{"ok": True}}\n\nif __name__ == "__main__":\n    app.run(port=5001)\n\n# Spec: {prompt.replace("`","")}\n'''
        return {"engine":"template","code":code,"model":None}
