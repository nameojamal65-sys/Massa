#!/usr/bin/env bash
set -e

echo "🚀 Building PAI6 Sovereign Control Interface (Light Mode)"

ROOT="$HOME/pai6_ui"
mkdir -p "$ROOT"/{api,web,logs}
cd "$ROOT"

pip install fastapi uvicorn jinja2 aiofiles rich psutil >/dev/null 2>&1

# ========== API CORE ==========
cat > api/main.py << 'PY'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import psutil, os, time

app = FastAPI(title="PAI6 Sovereign Control")

@app.get("/status")
def status():
    return {
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage("/").percent,
        "time": time.ctime()
    }

@app.get("/")
def dashboard():
    return HTMLResponse(open("web/index.html").read())
PY

# ========== WEB UI ==========
cat > web/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>PAI6 Sovereign Control</title>
<style>
body{background:#000;color:#0f0;font-family:monospace;text-align:center}
.box{border:1px solid #0f0;padding:20px;margin:20px}
</style>
</head>
<body>
<h1>☢️ PAI6 — Sovereign Control Interface</h1>
<div class="box" id="stats">Loading...</div>

<script>
async function update(){
  let r = await fetch('/status');
  let d = await r.json();
  document.getElementById('stats').innerHTML =
   "CPU: "+d.cpu+"%<br>"+
   "RAM: "+d.ram+"%<br>"+
   "DISK: "+d.disk+"%<br>"+
   "TIME: "+d.time;
}
setInterval(update,2000);
update();
</script>
</body>
</html>
HTML

# ========== RUNNER ==========
cat > run_ui.sh << 'SH'
#!/usr/bin/env bash
echo "🌐 Launching Sovereign UI -> http://127.0.0.1:9191"
uvicorn api.main:app --host 0.0.0.0 --port 9191
SH

chmod +x run_ui.sh

echo ""
echo "✅ PAI6 Sovereign UI READY"
echo "🚀 Start: ./run_ui.sh"
echo ""
