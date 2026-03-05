#!/data/data/com.termux/files/usr/bin/bash

echo "👑 Sovereign Autonomous Smart Launcher"
echo "====================================="

BASE="$HOME/sovereign_system"
LOG="$BASE/sovereign_full.log"

mkdir -p "$BASE"
cd "$BASE"

echo "🧠 Preparing system..."

# ---------- Core ----------
if [ ! -f core_launcher.py ]; then
cat > core_launcher.py << 'PY'
import time
print("🟢 Sovereign Core Active")
while True:
    time.sleep(5)
PY
chmod +x core_launcher.py
fi

# ---------- WebUI ----------
if [ ! -d webui ]; then
mkdir webui
cd webui

cat > package.json << 'JSON'
{
  "name": "sovereign-webui",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 8080"
  }
}
JSON

npm install vite

cd ..
fi

# ---------- Kill old ----------
echo "🧹 Cleaning ports..."
pkill -f vite 2>/dev/null
pkill -f core_launcher.py 2>/dev/null
pkill -f cloudflared 2>/dev/null

# ---------- Run Core ----------
echo "🚀 Starting Core..."
nohup python3 core_launcher.py >> "$LOG" 2>&1 &

# ---------- Run UI ----------
cd webui
PORT=8080
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; do
  PORT=$((PORT+1))
done

echo "🌐 Starting WebUI on $PORT ..."
nohup npx vite --host 0.0.0.0 --port $PORT >> "$LOG" 2>&1 &

sleep 5

# ---------- Tunnel ----------
echo "🌍 Opening Global Access Tunnel..."
cloudflared tunnel --url http://127.0.0.1:$PORT

