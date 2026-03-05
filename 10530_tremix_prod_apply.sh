#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
BASE="$HOME/Tremix"
TS="$(date +%Y%m%d_%H%M%S)"
BK="$HOME/tremix_master_backup_${TS}.py"

mkdir -p "$BASE"

if [ ! -f "$MASTER" ]; then
  echo "❌ ما لقيت $MASTER"
  exit 1
fi

echo "🧷 Backup -> $BK"
cp -f "$MASTER" "$BK"

echo "🔒 Enforce localhost-only bind (127.0.0.1)"
# Replace uvicorn host from 0.0.0.0 to 127.0.0.1 (best-effort for all occurrences)
# Works with both: uvicorn.run(app, host="0.0.0.0", port=...)
# and: uvicorn.run(... host='0.0.0.0' ...)
sed -i 's/host="0\.0\.0\.0"/host="127.0.0.1"/g; s/host='\''0\.0\.0\.0'\''/host='\''127.0.0.1'\''/g' "$MASTER" || true

echo "🧰 Ensure deps"
python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
python3 -m pip install fastapi uvicorn python-multipart >/dev/null 2>&1 || true

echo "🔐 Tight permissions"
# Sensitive files
touch "$BASE/users.json" "$BASE/tokens.json" "$BASE/sessions.json" "$BASE/registry.json" "$BASE/tasks.json" "$BASE/memory.json" >/dev/null 2>&1 || true
chmod 700 "$BASE" || true
chmod 700 "$BASE/outbox" "$BASE/inbox" "$BASE/projects" >/dev/null 2>&1 || true
chmod 600 "$BASE/users.json" "$BASE/tokens.json" "$BASE/sessions.json" "$BASE/memory.json" "$BASE/tasks.json" "$BASE/registry.json" >/dev/null 2>&1 || true
chmod 600 "$BASE/audit.log" "$BASE/tremix.log" >/dev/null 2>&1 || true

echo "🧹 Log rotate (simple)"
rotate_one () {
  f="$1"
  if [ -f "$f" ]; then
    sz=$(wc -c < "$f" | tr -d ' ')
    # rotate if > 1MB
    if [ "$sz" -gt 1048576 ]; then
      mv "$f" "${f}.${TS}.bak" || true
      : > "$f"
      chmod 600 "$f" || true
      echo "  rotated: $f"
    fi
  fi
}
rotate_one "$BASE/tremix.log"
rotate_one "$BASE/audit.log"
rotate_one "$BASE/supervisor.log"
rotate_one "$BASE/force_ui_8080.log"

echo "✅ Production patch applied."
echo "Next:"
echo "  1) nohup ~/tremix_supervisor.sh >/dev/null 2>&1 &"
echo "  2) ~/tremix_force_ui.sh"
