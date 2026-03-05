#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
mkdir -p _logs
chmod +x scripts/termux/*.sh || true

bash scripts/termux/build.sh | tee _logs/build.log

TOKEN="fm_dev_token"
./bin/forgemindd serve --addr :8080 --data ./data --token "$TOKEN" > _logs/server.log 2>&1 &
PID=$!
sleep 1

./bin/forgemindctl index --url http://127.0.0.1:8080 --token "$TOKEN" | tee _logs/ctl_index.log
./bin/forgemindctl enqueue --url http://127.0.0.1:8080 --token "$TOKEN" --spec samples/spec_go.json --pipe pipelines/golden_go.json | tee _logs/ctl_enqueue.log
sleep 2
./bin/forgemindctl q --url http://127.0.0.1:8080 --token "$TOKEN" --q "pipeline signing audit" | tee _logs/ctl_query.log
./bin/forgemindctl search --url http://127.0.0.1:8080 --q go | tee _logs/ctl_search.log
./bin/forgemindctl audit --url http://127.0.0.1:8080 | tee _logs/ctl_audit.log

curl -fsS http://127.0.0.1:8080/api/queue/status | tee _logs/ctl_queue_status.json
curl -fsS http://127.0.0.1:8080/api/queue/last | tee _logs/ctl_queue_last.json

kill $PID || true
echo "[doctor] ok"


# optional hardening smoke
bash scripts/termux/harden.sh || true
