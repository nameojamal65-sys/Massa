#!/usr/bin/env bash
set -e

echo "🤖 PAI6 Background Assistant Starting..."

LOG="$HOME/pai6_assistant.log"
touch "$LOG"

PKGS=(
flask fastapi uvicorn moviepy requests aiohttp sqlalchemy rich psutil
opencv-python numpy pillow torch torchvision torchaudio
)

function install_loop(){
  while true; do
    for p in "${PKGS[@]}"; do
      if ! python3 - << PY 2>/dev/null
import importlib; importlib.import_module("$p".replace("-","_"))
PY
      then
        echo "📦 Installing: $p" | tee -a "$LOG"
        pip install --no-cache-dir "$p" >> "$LOG" 2>&1 || true
      fi
    done
    sleep 60
  done
}

function system_monitor(){
  while true; do
    echo "🧠 System Check: $(date)" >> "$LOG"
    df -h >> "$LOG"
    free -m >> "$LOG"
    ps aux | wc -l >> "$LOG"
    echo "----------------------------" >> "$LOG"
    sleep 120
  done
}

install_loop &
system_monitor &

echo "☢️ PAI6 Terminal Assistant ONLINE"
echo "📜 Log file: $LOG"
echo "🛡 Running silently in background"
