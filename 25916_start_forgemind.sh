#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export FM_DATA="$HOME/ForgeMind_DRIVE/data"
export FM_LOGS="$HOME/ForgeMind_DRIVE/logs"
export FM_TOKEN="fm_dev_token"
export ADMIN="$HOME/ForgeMind_DRIVE/sovereign/out/forgemind_admin_end2end/forgemind_admin_end2end_cmd_forgemindadmin"

mkdir -p "$FM_DATA" "$FM_LOGS"

# Stop old
if [[ -f "$FM_LOGS/forgemind.pid" ]]; then kill "$(cat "$FM_LOGS/forgemind.pid")" 2>/dev/null || true; fi
if [[ -f "$FM_LOGS/admin.pid" ]]; then kill "$(cat "$FM_LOGS/admin.pid")" 2>/dev/null || true; fi

# Start core
nohup forgemind serve --addr 127.0.0.1:18080 --data "$FM_DATA" --token "$FM_TOKEN" > "$FM_LOGS/forgemind.log" 2>&1 &
echo $! > "$FM_LOGS/forgemind.pid"

# Start admin
nohup "$ADMIN" > "$FM_LOGS/admin.log" 2>&1 &
echo $! > "$FM_LOGS/admin.pid"

sleep 0.3

echo "Core health:"
curl -sS http://127.0.0.1:18080/api/health || true
echo
echo "Admin url:"
grep -Eo 'http://127\.0\.0\.1:[0-9]+/' "$FM_LOGS/admin.log" | tail -n 1 || true
