#!/usr/bin/env bash
set -e

echo "☢️  PAI6 — Sovereign UI Master Bootstrap"
echo "========================================"

ROOT="$HOME/pai6_sovereign_ui"
PYTHON=$(command -v python3 || command -v python)

echo "📂 Working Dir: $ROOT"
rm -rf "$ROOT"
mkdir -p "$ROOT"
cd "$ROOT"

echo "⚙️ Installing dependencies..."
pip install --upgrade pip >/dev/null 2>&1 || true
pip install flask fastapi uvicorn moviepy requests aiohttp sqlalchemy rich psutil >/dev/null 2>&1

mkdir -p core intelligence api dashboard video tools logs

# ================= CORE =================
cat > core/core.py << 'PY'
class SovereignCore:
    def __init__(self):
        self.state = "BOOTING"
    def boot(self):
        self.state = "ONLINE"
        print("🚀 Sovereign Core ONLINE")
    def status(self):
        return self.state
PY

# ================= AI ROUTER =================
cat > intelligence/router.py << 'PY'
class AIRouter:
    def route(self, task):
        if "video" in task.lower():
            return {"model":"video","task":task}
        if "code" in task.lower():
            return {"model":"code","task":task}
        return {"model":"analysis","task":task}
PY

# ================= VIDEO ENGINE =================
cat > video/video_gen.py << 'PY'
from moviepy.editor import TextClip

def text_to_video(text, filename="output.mp4"):
    clip = TextClip(text, fontsize=60, color='white', size=(1280,720))
    clip = clip.set_duration(6)
    clip.write_videofile(filename, fps=24)
    return filename
PY

# ================= API =================
cat > api/app.py << 'PY'
from fastapi import FastAPI
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel
from core.core import SovereignCore
from intelligence.router import AIRouter
from video.video_gen import text_to_video

app = FastAPI()

core = SovereignCore()
router = AIRouter()
core.boot()

class TextIn(BaseModel):
    text:str

@app.get("/status")
def status():
    return {"state":core.status()}

@app.post("/generate_video")
def generate_video(data:TextIn):
    file=text_to_video(data.text)
    return FileResponse(file,media_type="video/mp4",filename="pai6_output.mp4")

@app.get("/")
def dashboard():
    with open("dashboard/index.html") as f:
        return HTMLResponse(f.read())
PY

# ================= DASHBOARD =================
cat > dashboard/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>PAI6 Sovereign Control</title>
<style>
body{background:#050b1a;color:#00ffee;font-family:monospace;text-align:center}
.card{border:1px solid #00ffee;padding:20px;margin:20px;border-radius:10px}
button,input{padding:12px;margin:10px;background:black;color:#00ffee;border:1px solid #00ffee;font-size:16px}
</style>
</head>
<body>

<h1>☢️ PAI6 — Sovereign Command Center</h1>

<div class="card" id="status">Loading...</div>

<div class="card">
<h3>🎬 Text → Video Generator</h3>
<input id="txt" placeholder="Enter text here..." size="40"/>
<br>
<button onclick="gen()">Generate Video</button>
</div>

<script>
fetch('/status').then(r=>r.json()).then(d=>{
 document.getElementById("status").innerHTML="SYSTEM STATUS: "+d.state;
})

function gen(){
 fetch('/generate_video',{method:'POST',
 headers:{'Content-Type':'application/json'},
 body:JSON.stringify({text:document.getElementById('txt').value})
 }).then(r=>r.blob()).then(blob=>{
  let url=URL.createObjectURL(blob);
  let a=document.createElement('a');
  a.href=url;a.download="pai6_video.mp4";a.click();
 })
}
</script>

</body>
</html>
HTML

# ================= RUN SCRIPT =================
cat > run_ui.sh << 'RUN'
#!/usr/bin/env bash
echo "🚀 Launching PAI6 Sovereign UI System..."
uvicorn api.app:app --host 0.0.0.0 --port 8080
RUN

chmod +x run_ui.sh

echo ""
echo "☢️ SOVEREIGN UI DEPLOYMENT COMPLETE"
echo "==================================="
echo "🚀 Launch System:  ./run_ui.sh"
echo "🌐 Dashboard URL:  http://127.0.0.1:8080"
echo ""
