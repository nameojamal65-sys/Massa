#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="${ROOT:-$HOME/sovereign_core}"
PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"
BASE="http://$HOST:$PORT"

LOGDIR="$ROOT/logs"
mkdir -p "$LOGDIR"

SC_NEW_UI="${SC_NEW_UI:-1}"
SC_VERSION="${SC_VERSION:-1}"
SC_FREEZE="${SC_FREEZE:-0}"

# Health monitor settings
HEALTH_PATH="${HEALTH_PATH:-/health}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-5}"        # seconds
HEALTH_FAILS_BEFORE_RESTART="${HEALTH_FAILS_BEFORE_RESTART:-3}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-2}"          # curl seconds

UI_LOG="$LOGDIR/ui_prod.log"
CORE_LOG="$LOGDIR/core_prod.log"
MON_LOG="$LOGDIR/monitor.log"

UI_PIDF="$LOGDIR/ui.pid"
CORE_PIDF="$LOGDIR/core.pid"
MON_PIDF="$LOGDIR/monitor.pid"

ts(){ date "+%Y-%m-%d %H:%M:%S"; }
say(){ echo "[$(ts)] $*" | tee -a "$MON_LOG"; }

is_running_pidfile() {
  local f="$1"
  [ -f "$f" ] || return 1
  local p
  p="$(cat "$f" 2>/dev/null || true)"
  [ -n "${p:-}" ] || return 1
  kill -0 "$p" >/dev/null 2>&1
}

stop_processes() {
  # stop monitor first
  if is_running_pidfile "$MON_PIDF"; then
    kill "$(cat "$MON_PIDF")" >/dev/null 2>&1 || true
  fi
  rm -f "$MON_PIDF" >/dev/null 2>&1 || true

  # stop ui/core using pid files
  if is_running_pidfile "$UI_PIDF"; then
    kill "$(cat "$UI_PIDF")" >/dev/null 2>&1 || true
  fi
  if is_running_pidfile "$CORE_PIDF"; then
    kill "$(cat "$CORE_PIDF")" >/dev/null 2>&1 || true
  fi

  rm -f "$UI_PIDF" "$CORE_PIDF" >/dev/null 2>&1 || true

  # best-effort cleanup by pattern
  pkill -f "ui/server.py" >/dev/null 2>&1 || true
  pkill -f "core/core.py" >/dev/null 2>&1 || true
}

start_core() {
  ( cd "$ROOT" && python3 core/core.py >"$CORE_LOG" 2>&1 ) &
  echo $! > "$CORE_PIDF"
  say "core started pid=$(cat "$CORE_PIDF") log=$CORE_LOG"
}

start_ui() {
  ( cd "$ROOT" && SC_NEW_UI="$SC_NEW_UI" SC_VERSION="$SC_VERSION" SC_FREEZE="$SC_FREEZE" python3 ui/server.py >"$UI_LOG" 2>&1 ) &
  echo $! > "$UI_PIDF"
  say "ui started pid=$(cat "$UI_PIDF") log=$UI_LOG"
}

health_ok() {
  # Returns 0 if health endpoint returns 200 and ok:true (best-effort), else 1
  local out
  out="$(curl -sS --max-time "$HEALTH_TIMEOUT" -i "$BASE$HEALTH_PATH" 2>/dev/null || true)"
  echo "$out" | grep -qE '^HTTP/[^ ]+\s+200' || return 1
  # If JSON exists, try to check ok:true (non-fatal if not)
  echo "$out" | tr -d '\r' | tail -n 1 | grep -q '"ok":true' || true
  return 0
}

monitor_loop() {
  say "monitor started interval=${HEALTH_INTERVAL}s fails_before_restart=$HEALTH_FAILS_BEFORE_RESTART endpoint=$BASE$HEALTH_PATH"
  local fails=0

  while true; do
    # if processes are gone, treat as fail
    if ! is_running_pidfile "$UI_PIDF"; then
      fails=$((fails+1))
      say "health FAIL (ui process not running) fails=$fails/$HEALTH_FAILS_BEFORE_RESTART"
    elif ! is_running_pidfile "$CORE_PIDF"; then
      fails=$((fails+1))
      say "health FAIL (core process not running) fails=$fails/$HEALTH_FAILS_BEFORE_RESTART"
    elif ! health_ok; then
      fails=$((fails+1))
      say "health FAIL (endpoint) fails=$fails/$HEALTH_FAILS_BEFORE_RESTART"
    else
      # success resets counter
      [ "$fails" -ne 0 ] && say "health OK (reset fails counter)"
      fails=0
    fi

    if [ "$fails" -ge "$HEALTH_FAILS_BEFORE_RESTART" ]; then
      say "AUTO-RESTART triggered (fails=$fails). Restarting core+ui..."
      # stop core+ui (keep monitor alive)
      if is_running_pidfile "$UI_PIDF"; then kill "$(cat "$UI_PIDF")" >/dev/null 2>&1 || true; fi
      if is_running_pidfile "$CORE_PIDF"; then kill "$(cat "$CORE_PIDF")" >/dev/null 2>&1 || true; fi
      rm -f "$UI_PIDF" "$CORE_PIDF" >/dev/null 2>&1 || true
      pkill -f "ui/server.py" >/dev/null 2>&1 || true
      pkill -f "core/core.py" >/dev/null 2>&1 || true

      sleep 0.6
      start_core
      sleep 0.4
      start_ui
      fails=0
      say "AUTO-RESTART complete."
    fi

    sleep "$HEALTH_INTERVAL"
  done
}

start() {
  cd "$ROOT"
  : > "$MON_LOG" || true

  say "start requested ROOT=$ROOT BASE=$BASE flags: SC_NEW_UI=$SC_NEW_UI SC_VERSION=$SC_VERSION SC_FREEZE=$SC_FREEZE"
  stop_processes >/dev/null 2>&1 || true

  start_core
  sleep 0.6
  start_ui

  # initial smoke
  sleep 1
  say "smoke: /health"
  curl -sS --max-time 3 -i "$BASE/health" | head -n 20 | tee -a "$MON_LOG" >/dev/null || true
  say "smoke: /dash"
  curl -sS --max-time 3 -I "$BASE/dash" | head -n 15 | tee -a "$MON_LOG" >/dev/null || true

  # monitor in background
  ( monitor_loop ) >>"$MON_LOG" 2>&1 &
  echo $! > "$MON_PIDF"
  say "monitor pid=$(cat "$MON_PIDF") log=$MON_LOG"
  say "start complete"
}

stop() {
  say "stop requested"
  stop_processes
  say "stopped"
}

status() {
  echo "== status =="
  echo "ROOT: $ROOT"
  echo "BASE: $BASE"
  echo "Flags: SC_NEW_UI=$SC_NEW_UI SC_VERSION=$SC_VERSION SC_FREEZE=$SC_FREEZE"
  echo
  echo "PIDs:"
  if is_running_pidfile "$CORE_PIDF"; then echo " core: $(cat "$CORE_PIDF") (running)"; else echo " core: (not running)"; fi
  if is_running_pidfile "$UI_PIDF"; then echo " ui:   $(cat "$UI_PIDF") (running)"; else echo " ui:   (not running)"; fi
  if is_running_pidfile "$MON_PIDF"; then echo " mon:  $(cat "$MON_PIDF") (running)"; else echo " mon:  (not running)"; fi
  echo
  echo "Health:"
  curl -sS --max-time 2 -i "$BASE/health" | head -n 12 || true
}

logs() {
  echo "== monitor log (tail) =="; tail -n 120 "$MON_LOG" 2>/dev/null || true
  echo
  echo "== core log (tail) =="; tail -n 80 "$CORE_LOG" 2>/dev/null || true
  echo
  echo "== ui log (tail) =="; tail -n 160 "$UI_LOG" 2>/dev/null || true
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  logs) logs ;;
  *) echo "Usage: $0 {start|stop|status|logs}" ; exit 2 ;;
esac
