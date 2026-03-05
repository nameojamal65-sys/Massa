#!/bin/bash

BASE="$HOME/sovereign_core"
LOG="$BASE/logs"
UI="$BASE/ui"
CONF="$BASE/config"

mkdir -p $BASE $LOG $UI/templates $UI/static $CONF

echo "Initializing ForgeMind Sovereign Core..."

# Move binary
cp ~/sovereign_core_bin/* $BASE/ 2>/dev/null

# Nano Monitor
cat > $BASE/nano_monitor.sh << 'MON'
#!/bin/bash
CORE="$HOME/sovereign_core/core"
LOG="$HOME/sovereign_core/logs/monitor.log"

while true; do
  if ! pgrep -f core >/dev/null; then
    echo "[RESTART] $(date)" >> "$LOG"
    $CORE >> "$LOG" 2>&1 &
  fi
  sleep 5
done
MON
chmod +x $BASE/nano_monitor.sh

# Autostart
cat > $BASE/autostart.sh << 'AUTO'
#!/bin/bash
$HOME/sovereign_core/nano_monitor.sh &
python $HOME/sovereign_core/ui/server.py &
AUTO
chmod +x $BASE/autostart.sh

# Security
cat > $CONF/security.env << 'SEC'
MASTER_KEY=ZAEEM-ROOT-KEY
TIME_LOCK=OFF
REMOTE_OVERRIDE=ENABLED
SEC

# UI Server
cat > $UI/server.py << 'PY'
from flask import Flask, render_template, jsonify
import psutil, os

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("dashboard.html")

@app.route("/api/status")
def status():
    return jsonify({
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "procs": len(psutil.pids())
    })

@app.route("/api/restart")
def restart():
    os.system("pkill -f core")
    return jsonify({"status":"restarting"})

app.run(host="0.0.0.0", port=8080)
PY

# UI HTML
cat > $UI/templates/dashboard.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<title>ForgeMind Control</title>
<style>
body{background:#050b14;color:#00ffee;font-family:monospace}
.box{border:1px solid #00ffee;padding:15px;margin:15px}
button{background:#00ffee;color:black;padding:10px;border:none;font-weight:bold}
</style>
</head>
<body>
<h1>🧠 ForgeMind — Sovereign Control Panel</h1>
<div class="box" id="stats">Loading...</div>
<button onclick="fetch('/api/restart')">RESTART CORE</button>

<script>
async function load(){
let r = await fetch('/api/status');
let j = await r.json();
document.getElementById('stats').innerHTML =
`CPU: ${j.cpu}%<br>RAM: ${j.ram}%<br>Processes: ${j.procs}`;
}
setInterval(load,2000);
load();
</script>
</body>
</html>
HTML

echo "✅ Installation Complete"
echo "To start system run:"
echo "   ~/sovereign_core/autostart.sh"
