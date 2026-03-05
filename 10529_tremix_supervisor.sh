#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
BASE="$HOME/Tremix"
LOG="$BASE/supervisor.log"

mkdir -p "$BASE"

ts(){ date "+%Y-%m-%d %H:%M:%S"; }
log(){ echo "[$(ts)] $*" >> "$LOG"; }

start_dashboard(){
  pkill -f "tremix_master.py.*dashboard" 2>/dev/null || true
  nohup python3 "$MASTER" dashboard >> "$LOG" 2>&1 & disown || true
  log "dashboard start issued"
}

worker_alive(){
  python3 - <<'PY' >/dev/null 2>&1
import os, signal
BASE=os.path.expanduser("~/Tremix")
pidfile=os.path.join(BASE,"task_worker.pid")
def alive(pid):
    try: os.kill(pid,0); return True
    except: return False
if not os.path.exists(pidfile): raise SystemExit(1)
try:
    pid=int(open(pidfile).read().strip())
except: raise SystemExit(1)
raise SystemExit(0 if alive(pid) else 1)
PY
}

start_worker(){
  # يشتغل كـ process مستقل (و master بيكتب pidfile غالباً حسب نسخة المنظومة)
  nohup python3 "$MASTER" worker >> "$LOG" 2>&1 & disown || true
  log "worker start issued"
}

log "SUPERVISOR ONLINE"

while true; do
  # dashboard check
  if ! pgrep -f "tremix_master.py.*dashboard" >/dev/null 2>&1; then
    log "dashboard down -> restarting"
    start_dashboard
  fi

  # worker check
  if ! worker_alive; then
    log "worker down -> restarting"
    start_worker
  fi

  sleep 4
done
