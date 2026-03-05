#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="${MASTER:-$HOME/tremix_master.py}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
URL="http://${HOST}:${PORT}"
LOG="$HOME/Tremix/force_ui_${PORT}.log"

mkdir -p "$HOME/Tremix"

pkill -f "tremix_master.py.*dashboard" 2>/dev/null || true
pkill -f "uvicorn.*:${PORT}" 2>/dev/null || true

python3 -m pip install fastapi uvicorn python-multipart >/dev/null 2>&1 || true

nohup python3 "$MASTER" dashboard > "$LOG" 2>&1 & disown || true

# wait port open
OK=0
for i in $(seq 1 40); do
  python3 - <<PY >/dev/null 2>&1 && { OK=1; break; } || true
import socket
s=socket.socket(); s.settimeout(1)
s.connect(("${HOST}", ${PORT})); s.close()
PY
  sleep 0.5
done

if [ "$OK" -ne 1 ]; then
  echo "❌ الواجهة ما فتحت. شوف اللوق: $LOG"
  exit 1
fi

echo "✅ UI: $URL"
echo "📄 LOG: $LOG"

if command -v termux-open-url >/dev/null 2>&1; then
  termux-open-url "$URL" >/dev/null 2>&1 || true
fi
