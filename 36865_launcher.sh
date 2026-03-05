#!/data/data/com.termux/files/usr/bin/bash
while true; do
  echo "⚡ AUTONOMOUS CORE START"
  python3 -m sc_ops.autonomous.core || true
  echo "⚠ CORE CRASH — RESTARTING"
  sleep 1
done
