#!/data/data/com.termux/files/usr/bin/bash

set -e

PROJECT_DIR="/data/data/com.termux/files/home"
PORT=9000

echo "🛑 Killing existing uvicorn on $PORT (if any)..."
PID=$(ps -ef | grep -i "uvicorn" | grep "$PORT" | awk '{print $2}' || true)
if [ -n "$PID" ]; then
  kill -9 $PID || true
  sleep 1
fi

echo "🧹 Removing old SQLite DB..."
rm -f $PROJECT_DIR/pai6.db
rm -rf $PROJECT_DIR/storage 2>/dev/null || true

cd $PROJECT_DIR

echo "🐍 Activating venv..."
source .venv/bin/activate 2>/dev/null || true

echo "🚀 Starting uvicorn..."
nohup uvicorn app.main:app --host 127.0.0.1 --port $PORT > pai6.log 2>&1 &

echo "⏳ Waiting for server..."
sleep 2

echo "🔎 Checking openapi..."
curl -s http://127.0.0.1:$PORT/openapi.json > /dev/null

TENANT="AcmeAuto"
USER="admin_auto"
PASS="password123"

echo "🏗 Bootstrapping tenant..."
RESPONSE=$(curl -s -X POST http://127.0.0.1:$PORT/api/v1/tenants/bootstrap \
  -H "Content-Type: application/json" \
  -d "{\"tenant_name\":\"$TENANT\",\"admin_username\":\"$USER\",\"admin_password\":\"$PASS\"}")

TOKEN=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo ""
echo "✅ SERVER READY"
echo "----------------------------------"
echo "Tenant: $TENANT"
echo "Admin : $USER"
echo "Token : ${TOKEN:0:40}..."
echo "----------------------------------"

echo "🔐 Testing /users..."
curl -s http://127.0.0.1:$PORT/api/v1/users/ \
  -H "Authorization: Bearer $TOKEN"

echo ""
echo "🎉 DONE"
