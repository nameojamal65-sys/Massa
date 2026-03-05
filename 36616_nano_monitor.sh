#!/bin/bash
CORE="$HOME/sovereign_core/core"
LOG="$HOME/sovereign_core/logs/monitor.log"

while true; do
  if ! pgrep -f core >/dev/null; then
    echo "[RESTART] $(date)" >> "$LOG"
    $CORE >> "$LOG" 2>&1 &
  fi
  sleep 5
done
