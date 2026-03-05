#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
PORT="${PORT:-9000}"
: "${INVENTORY_API_KEY:=change-me-now}"
: "${INVENTORY_DB:=inventory.db}"
: "${INVENTORY_LOG:=inventory.log}"
: "${INVENTORY_RL_PER_MIN:=120}"

. .venv/bin/activate
nohup env INVENTORY_API_KEY="$INVENTORY_API_KEY" INVENTORY_DB="$INVENTORY_DB" INVENTORY_LOG="$INVENTORY_LOG" INVENTORY_RL_PER_MIN="$INVENTORY_RL_PER_MIN" \
  uvicorn app.main:app --host 127.0.0.1 --port "$PORT" > run.log 2>&1 & disown
echo "✅ running http://127.0.0.1:$PORT"
echo "🔑 x-api-key: $INVENTORY_API_KEY"
echo "🗄️  db: $INVENTORY_DB"
echo "🧾 run.log: $(pwd)/run.log"
