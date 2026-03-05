#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "☢️  SOVEREIGN NUCLEAR GLOBAL TUNNEL"
echo "================================="
echo

# Dependencies
for cmd in cloudflared curl wget; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "📦 Installing $cmd..."
    pkg install $cmd -y
  fi
done

# Install ngrok if missing
if ! command -v ngrok >/dev/null 2>&1; then
  echo "📦 Installing ngrok..."
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" ]]; then
    wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip
  else
    wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
  fi
  unzip -o ngrok.zip
  chmod +x ngrok
  mv ngrok $PREFIX/bin/
fi

echo "🚀 Starting Sovereign Core Tunnel System..."
echo

while true; do

  echo "🌐 Trying Cloudflare TCP Tunnel..."
  cloudflared tunnel --protocol http2 --url http://127.0.0.1:8080 &
  CF_PID=$!

  sleep 15

  if ps -p $CF_PID >/dev/null; then
    echo "✅ Cloudflare Tunnel Active (TCP MODE)"
    wait $CF_PID
  else
    echo "⚠️ Cloudflare failed. Switching to ngrok..."
    pkill cloudflared || true
    sleep 2

    echo "🚀 Launching ngrok..."
    ngrok http 8080
  fi

  echo "🔁 Tunnel dropped. Restarting in 5 seconds..."
  sleep 5

done
