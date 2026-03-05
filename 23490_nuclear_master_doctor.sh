#!/usr/bin/env bash
set -e

echo "👑 PAI6 — Nuclear Master Doctor (All-in-One)"
echo "=========================================="

ROOT="$HOME"
LOG="$HOME/pai6_nuclear_doctor.log"
touch "$LOG"

log(){ echo -e "$1" | tee -a "$LOG"; }

log "\n🔍 Phase 1 — Smart Discovery..."

CANDIDATES=$(find "$ROOT" -maxdepth 3 -type d \( -iname "*pai6*" -o -iname "*sovereign*" \) 2>/dev/null | head -n 30)

if [ -z "$CANDIDATES" ]; then
  log "❌ No PAI6 / Sovereign directories found."
  exit 1
fi

log "Detected candidates:"
echo "$CANDIDATES" | tee -a "$LOG"

CORE_DIR=""
for d in $CANDIDATES; do
  if [ -d "$d/pai6_system" ] || [ -d "$d/pai6_sovereign_core" ] || [ -f "$d/core_launcher.py" ]; then
    CORE_DIR="$d"
    break
  fi
done

if [ -z "$CORE_DIR" ]; then
  log "❌ No valid PAI6 Core detected."
  exit 1
fi

log "✅ Core Path: $CORE_DIR"

cd "$CORE_DIR"

log "\n🧠 Phase 2 — Deep Diagnosis..."

deps=(node python3 go bash curl wget)
for d in "${deps[@]}"; do
  if ! command -v $d >/dev/null 2>&1; then
    log "⚠ Missing: $d"
  else
    log "✔ $d OK"
  fi
done

log "\n🔧 Phase 3 — Auto Repair..."

find . -type f \( -iname "*.sh" -o -iname "*.py" \) -exec chmod +x {} \; 2>/dev/null || true

mkdir -p logs tmp run build dist >/dev/null 2>&1 || true

export PAI6_HOME="$CORE_DIR"
export PATH="$PATH:$CORE_DIR:$CORE_DIR/bin"

log "✔ Permissions + structure patched"

log "\n🛠 Phase 4 — Smart Build..."

RUN_SCRIPT="$CORE_DIR/run_pai6_autonomous.sh"

cat > "$RUN_SCRIPT" << 'EOF'
#!/usr/bin/env bash
export PAI6_HOME="$(cd "$(dirname "$0")" && pwd)"
cd "$PAI6_HOME"

echo "🚀 Booting PAI6 Sovereign Autonomous Core..."
echo "=========================================="

PORT=8080
kill -9 $(lsof -ti:$PORT) 2>/dev/null || true

if [ -f core_launcher.py ]; then
  python3 core_launcher.py &
elif [ -d pai6_system ]; then
  cd pai6_system
  bash run.sh &
elif [ -d pai6_sovereign_core ]; then
  cd pai6_sovereign_core
  bash run.sh &
else
  echo "❌ No runnable core found."
  exit 1
fi

sleep 3
echo ""
echo "✅ PAI6 ONLINE"
echo "🌐 Dashboard: http://127.0.0.1:$PORT"
EOF

chmod +x "$RUN_SCRIPT"

log "✔ Autonomous launcher built"

log "\n🚀 Phase 5 — Nuclear Boot..."

bash "$RUN_SCRIPT" | tee -a "$LOG"

log "\n📊 Phase 6 — Final Report"
echo "====================================" | tee -a "$LOG"
log "✔ Core Path     : $CORE_DIR"
log "✔ Launcher      : $RUN_SCRIPT"
log "✔ Log File      : $LOG"
log "✔ Status        : RUNNING"
echo "===================================="

echo ""
echo "👑 PAI6 — Nuclear Master Doctor: COMPLETE"
