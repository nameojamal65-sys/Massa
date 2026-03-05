import os, subprocess
from core.logger import log

class VoiceAgent:
    def __init__(self, base_dir: str):
        self.base_dir = base_dir
        os.makedirs(self.base_dir, exist_ok=True)

    def _espeak(self):
        for b in ("espeak","espeak-ng"):
            try:
                subprocess.check_output([b,"--version"], stderr=subprocess.STDOUT, text=True)
                return b
            except Exception:
                pass
        return None

    def tts(self, text: str, lang: str="ar"):
        text = (text or "مرحبا من SOVEREIGN CORE").strip()
        out = os.path.join(self.base_dir, "voice.wav")
        b = self._espeak()
        if b:
            log(f"VoiceAgent: using {b}")
            subprocess.check_output([b,"-v",lang,"-w",out,text], stderr=subprocess.STDOUT, text=True)
            return {"status":"voice_generated","output":out,"engine":b}
        return {"status":"no_tts","text":text,"hint":"pkg install espeak"}
