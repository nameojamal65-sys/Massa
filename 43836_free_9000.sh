#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PORT=9000

echo "🔎 Searching for process using :$PORT ..."
pid="$(ss -ltnp 2>/dev/null | awk -v p=":$PORT" '$4 ~ p {print $NF}' | head -n1 | sed -n 's/.*pid=\([0-9]\+\).*/\1/p')"

if [ -z "${pid:-}" ]; then
  pid="$(ps -ef | awk '/uvicorn/ && /--port 9000/ {print $2; exit}')"
fi

if [ -z "${pid:-}" ]; then
  echo "✅ No process found on :$PORT"
  exit 0
fi

echo "⚠️ Found PID=$pid using :$PORT"
echo "🛑 Killing PID=$pid ..."
kill -TERM "$pid" 2>/dev/null || true
sleep 0.3
kill -KILL "$pid" 2>/dev/null || true

echo "✅ Port :$PORT should be free now"
