#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
TOKEN="${TOKEN:-fm_dev_token}"
ADDR="${ADDR:-:8080}"
DATA="${DATA:-./data}"
./bin/forgemindd serve --addr "$ADDR" --data "$DATA" --token "$TOKEN"
