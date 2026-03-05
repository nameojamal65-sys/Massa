#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🚀 Starting Sovereign Autonomous System..."

BASE=~/sovereign_core
UI=$BASE/ui/server.py
CORE=$BASE/core

# قتل أي نسخ قديمة
pkill -f server.py 2>/dev/null
pkill -f core.py 2>/dev/null

# اختيار بورت ذكي
PORT=8080
while lsof -i :$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

# تشغيل النواة
if [ -d "$CORE" ]; then
  python3 $CORE/core.py >/dev/null 2>&1 &
fi

sleep 2

# تشغيل الواجهة
python3 $UI --port $PORT >/dev/null 2>&1 &

sleep 2

# فتح المتصفح تلقائياً
am start -a android.intent.action.VIEW -d http://127.0.0.1:$PORT >/dev/null 2>&1

echo "✅ Sovereign System Online"
echo "🌐 Dashboard: http://127.0.0.1:$PORT"
