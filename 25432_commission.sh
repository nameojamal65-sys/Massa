#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TOKEN="${TOKEN:-fm_dev_token}"
ADDR="${ADDR:-:8080}"
BASE="${BASE:-http://127.0.0.1:8080}"
DATA="${DATA:-./data}"

mkdir -p _logs

echo "[commission] build"
bash scripts/termux/build.sh | tee _logs/commission_build.log

echo "[commission] start server"
./bin/forgemindd serve --addr "$ADDR" --data "$DATA" --token "$TOKEN" > _logs/commission_server.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
sleep 1

echo "[commission] health"
curl -fsS "$BASE/health" | tee _logs/commission_health.txt

echo "[commission] knowledge index"
curl -fsS -X POST "$BASE/api/knowledge/index" -H "X-Auth-Token: $TOKEN" -H "Content-Type: application/json" -d '{}' | tee _logs/commission_index.json

echo "[commission] enqueue golden pipeline"
curl -fsS -X POST "$BASE/api/pipeline/enqueue" -H "X-Auth-Token: $TOKEN" -H "Content-Type: application/json"   -d '{"spec_path":"samples/spec_go.json","pipeline_path":"pipelines/golden_go.json"}' | tee _logs/commission_enqueue.json

sleep 2

echo "[commission] registry list"
curl -fsS "$BASE/api/registry/list" | tee _logs/commission_registry.json

echo "[commission] audit tail"
curl -fsS "$BASE/api/audit/tail?n=80" | tee _logs/commission_audit.json

echo "[commission] queue status"
curl -fsS "$BASE/api/queue/status" | tee _logs/commission_queue_status.json
echo
echo "[commission] last job"
curl -fsS "$BASE/api/queue/last" | tee _logs/commission_queue_last.json

echo "[commission] negative test: missing references should be rejected"
cat > _logs/spec_bad.json <<'JSON'
{
  "id": "",
  "intent": {"category":"automation","description":"try build without references", "language":"go"},
  "constraints": {"binary_first": true, "target_os": "windows"},
  "tenancy": {"tenant_id":"default"},
  "references": []
}
JSON

curl -fsS -X POST "$BASE/api/pipeline/enqueue" -H "X-Auth-Token: $TOKEN" -H "Content-Type: application/json"   -d '{"spec_path":"_logs/spec_bad.json","pipeline_path":"pipelines/golden_go.json"}' | tee _logs/commission_enqueue_bad.json

sleep 1
curl -fsS "$BASE/api/queue/last" | tee _logs/commission_queue_last_after_bad.json

echo "[commission] done"
