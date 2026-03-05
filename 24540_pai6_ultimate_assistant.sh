#!/usr/bin/env bash

set -e

echo "☢️ PAI6 ULTIMATE ASSISTANT — BOOTING..."

LOG="$HOME/pai6_ultimate_assistant.log"
touch "$LOG"

export PYTHONUNBUFFERED=1

CORE_PKGS=(
  flask fastapi uvicorn moviepy requests aiohttp sqlalchemy
  rich psutil opencv-python numpy pillow
  torch torchvision torchaudio
  transformers accelerate diffusers
)

SYSTEM_PKGS=(
  ffmpeg imagemagick clang make cmake pkg-config
)

function log(){
  echo "[$(date '+%F %T')] $1" | tee -a "$LOG"
}

function fix_pip(){
  log "🔧 Fixing pip environment..."
  python3 -m ensurepip --upgrade || true
  pip install --upgrade pip setuptools wheel >> "$LOG" 2>&1 || true
}

function system_deps(){
  for p in "${SYSTEM_PKGS[@]}"; do
    if ! command -v $p >/dev/null 2>&1; then
      log "📦 Installing system package: $p"
      pkg install -y $p >> "$LOG" 2>&1 || true
    fi
  done
}

function python_deps(){
  for p in "${CORE_PKGS[@]}"; do
    if ! python3 - << PY 2>/dev/null
import importlib; importlib.import_module("$p".replace("-","_"))
PY
    then
      log "📦 Installing python package: $p"
      pip install --no-cache-dir "$p" >> "$LOG" 2>&1 || true
    fi
  done
}

function deep_repair(){
  log "🧠 Deep Repair Mode Activated"
  pip cache purge >> "$LOG" 2>&1 || true
  rm -rf ~/.cache/pip
  fix_pip
}

function system_monitor(){
  while true; do
    log "📊 SYSTEM STATUS"
    df -h >> "$LOG"
    free -m >> "$LOG"
    top -bn1 | head -n 15 >> "$LOG"
    echo "------------------------------" >> "$LOG"
    sleep 90
  done
}

function ai_watchdog(){
  while true; do
    python_deps
    sleep 20
  done
}

function guardian_loop(){
  while true; do
    system_deps
    sleep 300
  done
}

log "🚀 Launching PAI6 Autonomous Assistant"

fix_pip
system_deps
python_deps

system_monitor &
ai_watchdog &
guardian_loop &

log "☢️ PAI6 ULTIMATE ASSISTANT — FULLY ONLINE"
log "🛡 Autonomous Background Guard Active"

wait
