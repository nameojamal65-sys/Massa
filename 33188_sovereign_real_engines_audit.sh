#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home
source .venv/bin/activate

BASE_API="${1:-http://127.0.0.1:9000}"
BASE_UI="${2:-http://127.0.0.1:9100}"

echo "======================================"
echo "   ✅ Sovereign Real Engines Audit"
echo "======================================"
echo

echo "🧭 Targets:"
echo "  API: $BASE_API"
echo "  UI : $BASE_UI"
echo

echo "🔌 Ports snapshot (9000/9100/8080):"
for p in 9000 9100 8080; do
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$p\$"; then
    echo "  ✅ :$p LISTEN"
  else
    echo "  ❌ :$p not listening"
  fi
done
echo

echo "🌐 API Health:"
curl -s "$BASE_API/health" || echo "❌ health failed"
echo; echo

echo "🔐 Login as admin (expects admin/password123):"
TOK="$(curl -s -X POST "$BASE_API/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}' \
  | python -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))')"

if [ -z "${TOK:-}" ]; then
  echo "❌ Login failed (no token). Maybe bootstrap not done or password mismatch."
  exit 1
fi
echo "✅ token OK (len=${#TOK})"
echo

authH=(-H "Authorization: Bearer $TOK")

echo "👤 Engine: USERS (GET /api/v1/users/)"
curl -s "$BASE_API/api/v1/users/" "${authH[@]}" | python -m json.tool || true
echo

echo "🧠 Engine: TASKS (POST + GET)"
echo "  -> creating task..."
TASK_ID="$(curl -s -X POST "$BASE_API/api/v1/tasks/" \
  "${authH[@]}" -H "Content-Type: application/json" \
  -d '{"type":"echo","input_json":{"ping":"pong"}}' \
  | python -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')"

if [ -z "${TASK_ID:-}" ]; then
  echo "❌ task create failed"
  exit 1
fi

echo "✅ created task id=$TASK_ID"
echo "  -> listing tasks..."
curl -s "$BASE_API/api/v1/tasks/" "${authH[@]}" | python -m json.tool || true
echo

echo "🔑 Engine: API KEYS (GET /api/v1/apikeys/)"
curl -s "$BASE_API/api/v1/apikeys/" "${authH[@]}" | python -m json.tool || true
echo

echo "📁 Engine: FILES (GET /api/v1/files/)"
curl -s "$BASE_API/api/v1/files/" "${authH[@]}" | python -m json.tool || true
echo

echo "🧾 UI Routes Probe:"
echo "  /ui/login:"
curl -s -I "$BASE_UI/ui/login" | head -n 5 || true
echo
echo "  /ui:"
curl -s -I "$BASE_UI/ui" | head -n 5 || true
echo

echo "======================================"
echo "   ✅ Audit finished (real calls done)"
echo "======================================"
