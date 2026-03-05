#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ---- Config ----
export FM_DATA="${FM_DATA:-$HOME/ForgeMind_DRIVE/data}"
export FM_LOGS="${FM_LOGS:-$HOME/ForgeMind_DRIVE/logs}"
export FM_TOKEN="${FM_TOKEN:-fm_dev_token}"
export CORE_ADDR="${CORE_ADDR:-127.0.0.1:18080}"
export ADMIN_BIN="${ADMIN_BIN:-$HOME/ForgeMind_DRIVE/sovereign/out/forgemind_admin_end2end/forgemind_admin_end2end_cmd_forgemindadmin}"
export FIXED_UI_PORT="${FIXED_UI_PORT:-45701}"

CORE_LOG="$FM_LOGS/forgemind.log"
ADMIN_LOG="$FM_LOGS/admin.log"
CORE_PID="$FM_LOGS/forgemind.pid"
ADMIN_PID="$FM_LOGS/admin.pid"
PROXY_PID="$FM_LOGS/ui_proxy.pid"

die(){ echo "ERROR: $*" >&2; exit 1; }
say(){ echo "== $*"; }

need_bin(){
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

pid_kill(){
  local pidfile="$1"
  [[ -f "$pidfile" ]] || return 0
  local pid; pid="$(cat "$pidfile" 2>/dev/null || true)"
  [[ -n "${pid:-}" ]] || return 0
  kill "$pid" 2>/dev/null || true
  rm -f "$pidfile" || true
}

admin_url_from_log(){
  # extracts last http://127.0.0.1:PORT/ from admin.log
  grep -Eo 'http://127\.0\.0\.1:[0-9]+/' "$ADMIN_LOG" 2>/dev/null | tail -n 1 || true
}

admin_port_from_log(){
  local url; url="$(admin_url_from_log)"
  [[ -n "${url:-}" ]] || { echo ""; return 0; }
  echo "$url" | sed -E 's#http://127\.0\.0\.1:([0-9]+)/#\1#'
}

healthcheck(){
  local url="$1"
  curl -sS --max-time 2 "$url" >/dev/null
}

cmd_up(){
  need_bin curl
  need_bin nohup
  need_bin socat

  mkdir -p "$FM_DATA" "$FM_LOGS"

  say "Stopping any previous processes (pidfiles)..."
  pid_kill "$PROXY_PID"
  pid_kill "$ADMIN_PID"
  pid_kill "$CORE_PID"

  say "Starting Core on $CORE_ADDR ..."
  nohup forgemind serve \
    --addr "$CORE_ADDR" \
    --data "$FM_DATA" \
    --token "$FM_TOKEN" \
    > "$CORE_LOG" 2>&1 &
  echo $! > "$CORE_PID"

  say "Waiting Core /api/health ..."
  for i in 1 2 3 4 5; do
    if healthcheck "http://$CORE_ADDR/api/health"; then break; fi
    sleep 0.2
  done
  if ! healthcheck "http://$CORE_ADDR/api/health"; then
    tail -n 80 "$CORE_LOG" || true
    die "Core healthcheck failed at http://$CORE_ADDR/api/health"
  fi

  say "Checking Admin binary exists..."
  [[ -x "$ADMIN_BIN" ]] || die "Admin binary not executable or missing: $ADMIN_BIN"

  say "Starting Admin (auto-port) ..."
  nohup "$ADMIN_BIN" > "$ADMIN_LOG" 2>&1 &
  echo $! > "$ADMIN_PID"

  say "Waiting Admin to print its URL..."
  local admin_port=""
  for i in 1 2 3 4 5 6 7 8 9 10; do
    admin_port="$(admin_port_from_log)"
    [[ -n "${admin_port:-}" ]] && break
    sleep 0.2
  done
  [[ -n "${admin_port:-}" ]] || { tail -n 120 "$ADMIN_LOG" || true; die "Could not detect Admin port from logs"; }

  say "Admin internal URL: http://127.0.0.1:${admin_port}/"
  say "Starting fixed UI proxy: 127.0.0.1:${FIXED_UI_PORT} -> 127.0.0.1:${admin_port}"
  nohup socat \
    TCP-LISTEN:${FIXED_UI_PORT},fork,reuseaddr \
    TCP:127.0.0.1:${admin_port} \
    > "$FM_LOGS/ui_proxy.log" 2>&1 &
  echo $! > "$PROXY_PID"

  say "Healthchecks via fixed port..."
  curl -sS "http://127.0.0.1:${FIXED_UI_PORT}/api/health" | head -c 200; echo
  curl -sS "http://127.0.0.1:${FIXED_UI_PORT}/api/config/get" | head -c 300; echo

  say "DONE."
  echo "Core:   http://$CORE_ADDR/"
  echo "Admin:  http://127.0.0.1:${FIXED_UI_PORT}/   (fixed)"
}

cmd_down(){
  say "Stopping..."
  pid_kill "$PROXY_PID"
  pid_kill "$ADMIN_PID"
  pid_kill "$CORE_PID"
  say "Stopped."
}

cmd_status(){
  say "Core PID:  $(cat "$CORE_PID" 2>/dev/null || echo -)"
  say "Admin PID: $(cat "$ADMIN_PID" 2>/dev/null || echo -)"
  say "Proxy PID: $(cat "$PROXY_PID" 2>/dev/null || echo -)"
  echo "Fixed Admin URL: http://127.0.0.1:${FIXED_UI_PORT}/"
  echo -n "Core health:  "
  curl -sS --max-time 2 "http://$CORE_ADDR/api/health" 2>/dev/null || echo "FAIL"
  echo -n "Admin health: "
  curl -sS --max-time 2 "http://127.0.0.1:${FIXED_UI_PORT}/api/health" 2>/dev/null || echo "FAIL"
}

cmd_verify(){
  # "جاهزة للتشغيل" محليًا (باينري + إعدادات + endpoints)
  need_bin curl
  say "Verifying binaries..."
  command -v forgemind >/dev/null 2>&1 || die "forgemind not found in PATH"
  [[ -x "$ADMIN_BIN" ]] || die "Admin binary missing or not executable: $ADMIN_BIN"

  say "Verifying directories..."
  mkdir -p "$FM_DATA" "$FM_LOGS"

  say "Verifying local endpoints (expects services already up)..."
  curl -sS "http://$CORE_ADDR/api/health" | head -c 200; echo
  curl -sS "http://127.0.0.1:${FIXED_UI_PORT}/api/health" | head -c 200; echo
  curl -sS "http://127.0.0.1:${FIXED_UI_PORT}/api/config/get" | head -c 500; echo

  say "OK: local platform looks ready."
}

case "${1:-}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  verify) cmd_verify ;;
  *) echo "Usage: $0 {up|down|status|verify}"; exit 2 ;;
esac
