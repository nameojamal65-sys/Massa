#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd /data/data/com.termux/files/home

# shellcheck disable=SC1091
source .venv/bin/activate

HOST="127.0.0.1"
PORTS="9000 9100 9200 9300 9400"

pick_port() {
  for p in $PORTS; do
    if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$p$"; then
      continue
    fi
    echo "$p"
    return 0
  done
  return 1
}

PORT="$(pick_port || true)"
if [ -z "${PORT:-}" ]; then
  echo "❌ ما لقيت بورت فاضي ضمن: $PORTS"
  exit 1
fi

echo "✅ Starting server on http://$HOST:$PORT"
echo "   Open docs: http://$HOST:$PORT/docs"
echo "   (CTRL+C to stop)"
exec uvicorn app.main:app --host "$HOST" --port "$PORT"
