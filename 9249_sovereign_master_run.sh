#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="${ROOT:-$HOME/sovereign_core}"
PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"
BASE="http://$HOST:$PORT"
REPORT_DIR="$ROOT/logs"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$REPORT_DIR/sovereign_report_$TS.txt"

SC_NEW_UI_VALUE="${SC_NEW_UI_VALUE:-1}"   # 1 = enable /dash, 0 = disable
SC_VERSION_VALUE="${SC_VERSION_VALUE:-1}"
SC_FREEZE_VALUE="${SC_FREEZE_VALUE:-0}"

mkdir -p "$REPORT_DIR"

log() { echo -e "$*" | tee -a "$REPORT"; }
hr()  { log "\n------------------------------------------------------------\n"; }

log "== Sovereign Master Run (All-in-One) =="
log "Time: $(date)"
log "ROOT: $ROOT"
log "BASE: $BASE"
log "Flags: SC_NEW_UI=$SC_NEW_UI_VALUE SC_VERSION=$SC_VERSION_VALUE SC_FREEZE=$SC_FREEZE_VALUE"
hr

# 0) Ensure root exists
if [ ! -d "$ROOT" ]; then
  log "❌ ROOT not found: $ROOT"
  exit 1
fi

cd "$ROOT"
log "✅ Entered project root: $(pwd)"
hr

# 1) Stop prior servers (best-effort)
log "== Step 1: Stop existing UI servers (best-effort) =="
pkill -f "ui/server.py" >/dev/null 2>&1 || true
pkill -f "python.*server.py" >/dev/null 2>&1 || true
pkill -f "flask.*run" >/dev/null 2>&1 || true
log "✅ Stop signals sent."
hr

# 2) Install/verify patch pack v1
log "== Step 2: Install/verify Patch Pack v1 =="
if [ -x "$HOME/sc_patch_pack_v1.sh" ]; then
  log "Found: $HOME/sc_patch_pack_v1.sh"
  bash "$HOME/sc_patch_pack_v1.sh" | tee -a "$REPORT"
else
  log "❌ Patch pack not found/executable at: $HOME/sc_patch_pack_v1.sh"
  log "   Put it there first or re-create it."
  exit 1
fi

if grep -q "SC_RELEASE_LOCK_BEGIN" "$ROOT/ui/server.py"; then
  log "✅ Marker found in ui/server.py (patched)."
else
  log "❌ Marker NOT found in ui/server.py after patch. Abort."
  exit 1
fi
hr

# 3) Start UI with correct PYTHONPATH so sc_platform imports work
log "== Step 3: Start UI server (PYTHONPATH=. to fix imports) =="

UI_LOG="$REPORT_DIR/ui_$TS.log"
log "UI log: $UI_LOG"

# Start in background
(
  cd "$ROOT"
  export PYTHONPATH="."
  export SC_NEW_UI="$SC_NEW_UI_VALUE"
  export SC_VERSION="$SC_VERSION_VALUE"
  export SC_FREEZE="$SC_FREEZE_VALUE"
  python3 ui/server.py
) >"$UI_LOG" 2>&1 &

UI_PID=$!
log "✅ UI started (pid=$UI_PID)"

# Give it a moment
sleep 1.2

# If exited quickly, show error
if ! kill -0 "$UI_PID" >/dev/null 2>&1; then
  log "❌ UI process exited early. Showing last 120 lines of UI log:"
  tail -n 120 "$UI_LOG" | tee -a "$REPORT"
  exit 1
fi

hr

# 4) Tests
log "== Step 4: Smoke tests =="

curl_i () {
  local url="$1"
  log "\n$ curl -i $url"
  # -sS silent but show errors, --max-time avoid hanging
  curl -sS --max-time 5 -i "$url" 2>&1 | tee -a "$REPORT" || true
}

curl_I () {
  local url="$1"
  log "\n$ curl -I $url"
  curl -sS --max-time 5 -I "$url" 2>&1 | tee -a "$REPORT" || true
}

curl_s () {
  local url="$1"
  log "\n$ curl -s $url"
  curl -sS --max-time 5 "$url" 2>&1 | tee -a "$REPORT" || true
}

curl_i "$BASE/health"
curl_I "$BASE/"
curl_I "$BASE/dash"
curl_s "$BASE/api/status"

hr

# 5) Summary extraction
log "== Step 5: Summary =="

# Helper to extract HTTP status from report section quickly
health_status="$(grep -m1 -Eo 'HTTP/[0-9.]+\s+[0-9]{3}' "$REPORT" | head -n1 || true)"
dash_status="$(grep -A2 -n "\$ curl -I $BASE/dash" "$REPORT" | grep -Eo 'HTTP/[0-9.]+\s+[0-9]{3}' | head -n1 || true)"

log "Report file: $REPORT"
log "UI log file: $UI_LOG"
log "UI pid: $UI_PID"
log "First seen HTTP status (from report): ${health_status:-N/A}"
log "/dash status (from report): ${dash_status:-N/A}"

log "\n✅ Master Run complete."
log "To stop UI: kill $UI_PID"
