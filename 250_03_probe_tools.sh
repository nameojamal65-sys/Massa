#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="${1:-http://127.0.0.1:9000}"

echo "==[ STAGE 3: PROBE TOOLS ]================="
echo "BASE: $BASE"
echo

echo "🌐 Health:"
curl -s "$BASE/health" || true
echo; echo

echo "🧰 List tools:"
curl -s "$BASE/api/v1/tools" | python -m json.tool || true
echo; echo

echo "🔧 Run health_ping:"
curl -s -X POST "$BASE/api/v1/tools/run" \
  -H "Content-Type: application/json" \
  -d '{"name":"health_ping","input":{"msg":"hello"}}' \
  | python -m json.tool || true
echo; echo

echo "📊 Run db_stats:"
curl -s -X POST "$BASE/api/v1/tools/run" \
  -H "Content-Type: application/json" \
  -d '{"name":"db_stats","input":{}}' \
  | python -m json.tool || true
echo

echo "=========================================="
