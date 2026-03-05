#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home
source .venv/bin/activate

BASE="http://127.0.0.1:9000"

echo "🌐 Health:"
curl -s "$BASE/health" || true
echo
echo

echo "🚀 Bootstrapping tenant+admin..."
curl -s -X POST "$BASE/api/v1/tenants/bootstrap" \
  -H "Content-Type: application/json" \
  -d '{"tenant_name":"Acme","admin_username":"admin","admin_password":"password123"}' | sed 's/\\n/\n/g'
echo
echo

echo "🔑 Logging in..."
TOK="$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}' | python -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')"

echo "✅ token acquired (len=${#TOK})"
echo

echo "👤 List users:"
curl -s "$BASE/api/v1/users/" -H "Authorization: Bearer $TOK" | python -m json.tool || true
echo

echo "🧠 Create a task (echo)..."
curl -s -X POST "$BASE/api/v1/tasks/" \
  -H "Authorization: Bearer $TOK" \
  -H "Content-Type: application/json" \
  -d '{"type":"echo","input_json":{"x":1}}' | python -m json.tool || true
echo

echo "📦 List tasks:"
curl -s "$BASE/api/v1/tasks/" -H "Authorization: Bearer $TOK" | python -m json.tool || true
echo
