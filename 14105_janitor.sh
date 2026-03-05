#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="${ROOT:-./workspaces/tenants}"
DAYS="${DAYS:-7}"
if [[ ! -d "$ROOT" ]]; then echo "[janitor] no workspaces"; exit 0; fi
# delete req_* older than DAYS
find "$ROOT" -type d -name 'req_*' -mtime +"$DAYS" -print -exec rm -rf {} + 2>/dev/null || true
echo "[janitor] done"
