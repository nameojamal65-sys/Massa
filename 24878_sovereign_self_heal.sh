#!/data/data/com.termux/files/usr/bin/bash
while true; do
 pgrep -f sovereign_dashboard.py >/dev/null || \
 python sovereign_dashboard.py 8082 >/dev/null 2>&1 &
 sleep 10
done
