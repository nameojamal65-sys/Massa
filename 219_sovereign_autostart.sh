#!/data/data/com.termux/files/usr/bin/bash

clear
echo "👑 Sovereign Autonomous Smart Launcher"
echo "====================================="

BASE="$HOME/sovereign_system"

# Detect base path
if [ ! -d "$BASE" ]; then
  echo "❌ sovereign_system not found"
  echo "➡️  Searching..."
  FOUND=$(find $HOME -type d -name sovereign_system 2>/dev/null | head -n 1)
  if [ -z "$FOUND" ]; then
    echo "❌ System not found. Abort."
    exit 1
  else
    BASE="$FOUND"
  fi
fi

echo "📍 Base Path: $BASE"

cd "$BASE" || exit 1

# Kill old ports
echo "🧹 Cleaning old ports..."
pkill -f vite >/dev/null 2>&1
pkill -f orchestrator >/dev/null 2>&1
pkill -f cloudflared >/dev/null 2>&1

sleep 1

# Patch Vite config
echo "🛠️  Patching Vite security..."
VITE_CFG="$BASE/webui/vite.config.js"

if [ -f "$VITE_CFG" ]; then
cat > "$VITE_CFG" << 'JS'
import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    host: true,
    port: 8080,
    strictPort: false,
    allowedHosts: ['all']
  }
})
JS
fi

# Start core
echo "🚀 Starting Sovereign Core..."
nohup python core_launcher.py >> sovereign_full.log 2>&1 &

sleep 2

# Start WebUI
echo "🌐 Starting Web UI..."
cd "$BASE/webui" || exit 1
nohup npx vite --host 0.0.0.0 --port 8080 >> ../sovereign_full.log 2>&1 &

sleep 4

# Start Cloudflare Tunnel
echo "🌍 Opening global access tunnel..."
cloudflared tunnel --url http://127.0.0.1:8080 | tee "$BASE/global_url.txt"

