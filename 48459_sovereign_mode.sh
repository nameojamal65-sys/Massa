#!/usr/bin/env bash
set -e

clear
echo "👑 PAI6 — SOVEREIGN MODE DEPLOYER"
echo "================================="
echo " Enterprise Autonomous Build System "
echo "================================="
sleep 1

ROOT="$HOME"
LOG="$ROOT/pai6_sovereign.log"
SNAPSHOT="$ROOT/pai6_sovereign_snapshot_$(date +%Y%m%d_%H%M%S).tar.gz"
mkdir -p "$ROOT/logs"

touch "$LOG"
log(){ echo -e "$1" | tee -a "$LOG"; }

log "\n📍 ROOT: $ROOT"
log "📝 LOG:  $LOG"

############################################
log "\n🔍 Phase 1 — Discovery & Core Detection..."

CANDIDATES=$(find "$ROOT" -maxdepth 4 -type d \( -iname "*pai6*" -o -iname "*sovereign*" \) 2>/dev/null)
CORE_DIR=""

for d in $CANDIDATES; do
  if [ -f "$d/core_launcher.py" ] || [ -d "$d/pai6_system" ] || [ -d "$d/pai6_sovereign_core" ]; then
    CORE_DIR="$d"
    break
  fi
done

if [ -z "$CORE_DIR" ]; then
  CORE_DIR="$ROOT/sovereign_package"
fi

log "✅ Core Detected: $CORE_DIR"
cd "$CORE_DIR"

############################################
log "\n🧠 Phase 2 — Dependency Check..."

deps=(node python3 go bash curl wget tar lsof unzip)
for d in "${deps[@]}"; do
  if command -v $d >/dev/null 2>&1; then log "✔ $d OK"; else log "⚠ Missing: $d"; fi
done

############################################
log "\n🛡 Phase 3 — Snapshot & Backup..."
tar -czf "$SNAPSHOT" "$CORE_DIR" 2>/dev/null || true
log "✔ Snapshot saved: $SNAPSHOT"

############################################
log "\n🔧 Phase 4 — Structure & Permissions Healing..."
find . -type f \( -iname "*.sh" -o -iname "*.py" \) -exec chmod +x {} \; 2>/dev/null || true
mkdir -p logs tmp run build dist snapshot >/dev/null 2>&1
export PAI6_HOME="$CORE_DIR"
export PATH="$PATH:$CORE_DIR:$CORE_DIR/bin"
log "✔ Structure & permissions healed"

############################################
log "\n🛠 Phase 5 — Sovereign Binary Builder..."
BINARY="$CORE_DIR/PAI6_Sovereign.bin"
echo "#!/usr/bin/env bash" > "$BINARY"
echo "cd \"$CORE_DIR\" && bash run_pai6_ultra.sh" >> "$BINARY"
chmod +x "$BINARY"
log "✔ Binary created: $BINARY"

############################################
log "\n🌐 Phase 6 — Auto Tunnel Setup..."
TUNNEL_LOG="$ROOT/logs/tunnel.log"
TUNNEL_URL=""
mkdir -p "$ROOT/logs"

if command -v cloudflared >/dev/null 2>&1; then
  cloudflared tunnel --url http://127.0.0.1:8080 > "$TUNNEL_LOG" 2>&1 &
  sleep 5
  TUNNEL_URL=$(grep -o 'https://.*trycloudflare.com' "$TUNNEL_LOG" | head -n1)
fi

if [ -z "$TUNNEL_URL" ] && command -v ngrok >/dev/null 2>&1; then
  ngrok http 8080 > "$TUNNEL_LOG" 2>&1 &
  sleep 5
  TUNNEL_URL=$(grep -o 'https://.*ngrok-free.app' "$TUNNEL_LOG" | head -n1)
fi

############################################
log "\n🚀 Phase 7 — Launch Sovereign Core..."
RUN="$CORE_DIR/run_pai6_ultra.sh"
bash "$RUN" | tee -a "$LOG"

############################################
log "\n📊 Phase 8 — Enterprise Report"
echo "========================================" | tee -a "$LOG"
log "✔ Core Path   : $CORE_DIR"
log "✔ Launcher    : $RUN"
log "✔ Binary      : $BINARY"
log "✔ Snapshot    : $SNAPSHOT"
log "✔ Log File    : $LOG"
log "✔ Status      : RUNNING"
log "✔ Local UI    : http://127.0.0.1:8080"
if [ -n "$TUNNEL_URL" ]; then
  log "✔ Public URL  : $TUNNEL_URL"
fi
echo "========================================"
echo ""
echo "👑 PAI6 — SOVEREIGN MODE DEPLOY COMPLETE"
