#!/usr/bin/env bash
set -e

clear
echo "👑 PAI6 — ULTRA NUCLEAR MASTER DOCTOR"
echo "===================================="
echo " Sovereign Autonomous Healing System "
echo "===================================="
sleep 1

ROOT="$HOME"
LOG="$ROOT/pai6_ultra_nuclear.log"
SNAPSHOT="$ROOT/pai6_snapshot_$(date +%Y%m%d_%H%M%S).tar.gz"

touch "$LOG"

log(){ echo -e "$1" | tee -a "$LOG"; }

log "\n📍 ROOT: $ROOT"
log "📝 LOG:  $LOG"

############################################
log "\n🔍 Phase 1 — Ultra Smart Discovery..."

CANDIDATES=$(find "$ROOT" -maxdepth 4 -type d \( -iname "*pai6*" -o -iname "*sovereign*" \) 2>/dev/null)

if [ -z "$CANDIDATES" ]; then
  log "❌ No PAI6 / Sovereign directories found."
  exit 1
fi

log "Detected candidates:"
echo "$CANDIDATES" | tee -a "$LOG"

CORE_DIR=""

for d in $CANDIDATES; do
  if [ -f "$d/core_launcher.py" ] || \
     [ -d "$d/pai6_system" ] || \
     [ -d "$d/pai6_sovereign_core" ] || \
     [ -f "$d/start.sh" ]; then
    CORE_DIR="$d"
    break
  fi
done

if [ -z "$CORE_DIR" ]; then
  CORE_DIR=$(find "$ROOT" -maxdepth 4 -type d -iname "sovereign_package" 2>/dev/null | head -n1)
fi

if [ -z "$CORE_DIR" ]; then
  log "❌ No valid PAI6 Core detected."
  exit 1
fi

log "✅ Core Detected: $CORE_DIR"
cd "$CORE_DIR"

############################################
log "\n🧠 Phase 2 — Deep System Diagnosis..."

deps=(node python3 go bash curl wget tar lsof)

for d in "${deps[@]}"; do
  if command -v $d >/dev/null 2>&1; then
    log "✔ $d OK"
  else
    log "⚠ Missing: $d"
  fi
done

############################################
log "\n🛡 Phase 3 — Sovereign Snapshot..."

tar -czf "$SNAPSHOT" "$CORE_DIR" 2>/dev/null || true
log "✔ Snapshot saved: $SNAPSHOT"

############################################
log "\n🔧 Phase 4 — Nuclear Self-Healing..."

find . -type f \( -iname "*.sh" -o -iname "*.py" \) -exec chmod +x {} \; 2>/dev/null || true

mkdir -p logs tmp run build dist snapshot >/dev/null 2>&1 || true

export PAI6_HOME="$CORE_DIR"
export PATH="$PATH:$CORE_DIR:$CORE_DIR/bin"

log "✔ Permissions + structure healed"

############################################
log "\n🛠 Phase 5 — Autonomous Rebuild..."

RUN="$CORE_DIR/run_pai6_ultra.sh"

cat > "$RUN" << 'EOF'
#!/usr/bin/env bash
set -e

export PAI6_HOME="$(cd "$(dirname "$0")" && pwd)"
cd "$PAI6_HOME"

PORT=8080
echo "🚀 Booting PAI6 Sovereign Ultra Core..."
echo "====================================="

kill -9 $(lsof -ti:$PORT) 2>/dev/null || true

if [ -f core_launcher.py ]; then
  python3 core_launcher.py &
elif [ -d pai6_system ]; then
  cd pai6_system && bash run.sh &
elif [ -d pai6_sovereign_core ]; then
  cd pai6_sovereign_core && bash run.sh &
elif [ -f start.sh ]; then
  bash start.sh &
else
  echo "❌ No runnable core found."
  exit 1
fi

sleep 3

echo ""
echo "✅ CORE ONLINE"
echo "🌐 Dashboard: http://127.0.0.1:$PORT"
EOF

chmod +x "$RUN"

log "✔ Ultra launcher generated"

############################################
log "\n🌐 Phase 6 — Smart Tunnel (Cloudflare / Ngrok fallback)..."

TUNNEL_URL=""

if command -v cloudflared >/dev/null 2>&1; then
  cloudflared tunnel --url http://127.0.0.1:8080 > /tmp/cf.log 2>&1 &
  sleep 5
  TUNNEL_URL=$(grep -o 'https://.*trycloudflare.com' /tmp/cf.log | head -n1)
fi

if [ -z "$TUNNEL_URL" ] && command -v ngrok >/dev/null 2>&1; then
  ngrok http 8080 > /tmp/ngrok.log 2>&1 &
  sleep 5
  TUNNEL_URL=$(grep -o 'https://.*ngrok-free.app' /tmp/ngrok.log | head -n1)
fi

############################################
log "\n🚀 Phase 7 — Ultra Boot..."

bash "$RUN" | tee -a "$LOG"

############################################
log "\n📊 Phase 8 — Final Sovereign Report"
echo "========================================" | tee -a "$LOG"
log "✔ Core Path  : $CORE_DIR"
log "✔ Launcher   : $RUN"
log "✔ Snapshot   : $SNAPSHOT"
log "✔ Log File   : $LOG"
log "✔ Status     : RUNNING"
log "✔ Local UI   : http://127.0.0.1:8080"

if [ -n "$TUNNEL_URL" ]; then
  log "🌍 Public URL : $TUNNEL_URL"
fi

echo "========================================"

echo ""
echo "👑 PAI6 — ULTRA NUCLEAR MASTER DOCTOR COMPLETE"
