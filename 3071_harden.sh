#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
TOKEN="${TOKEN:-fm_dev_token}"
BASE="${BASE:-http://127.0.0.1:8080}"
DATA="${DATA:-./data}"

mkdir -p _logs
bash scripts/termux/build.sh | tee _logs/harden_build.log

./bin/forgemindd serve --addr :8080 --data "$DATA" --token "$TOKEN" > _logs/harden_server.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
sleep 1

echo "[harden] headers"
curl -fsSI "$BASE/" | tee _logs/harden_headers.txt
grep -qi "x-content-type-options" _logs/harden_headers.txt
grep -qi "content-security-policy" _logs/harden_headers.txt

echo "[harden] cors preflight"
curl -fsS -X OPTIONS "$BASE/api/registry/list" -H "Origin: http://127.0.0.1:8080" -H "Access-Control-Request-Method: GET" -I | tee _logs/harden_cors.txt
grep -qi "access-control-allow-origin" _logs/harden_cors.txt

echo "[harden] rate limit smoke"
# burst a bit; expect not to crash; may get 429s which is fine
for i in $(seq 1 6); do
  (curl -s -o /dev/null -w "%{http_code}\n" "$BASE/health") || true
done | tee _logs/harden_ratelimit_codes.txt

echo "[harden] ok"
