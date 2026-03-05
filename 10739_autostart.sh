#!/usr/bin/env bash
# Sovereign Core + UI AutoStart
BASE="$HOME/sovereign_core"
CORE="$BASE/core"
UI="$BASE/ui"
PORT=8080

# إيقاف أي نسخة شغالة
pkill -f core.py
pkill -f server.py

# تشغيل Core وUI في الخلفية
python3 "$CORE/core.py" &
python3 "$UI/server.py" &

echo "✅ Sovereign Core + UI running! Open browser at http://localhost:$PORT (or next free port if 8080 is busy)"
