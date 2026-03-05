#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🚀 Booting Sovereign Core Autonomous System..."
sleep 1

BASE="$HOME/sovereign_core"
CORE="$BASE/core"
UI="$BASE/ui"

# قتل أي نسخة قديمة
pkill -f core.py >/dev/null 2>&1
pkill -f server.py >/dev/null 2>&1

# تشغيل النواة
python3 "$CORE/core.py" > /dev/null 2>&1 &

# تشغيل الواجهة
python3 "$UI/server.py" > /dev/null 2>&1 &

sleep 3

# فتح المتصفح تلقائياً
termux-open-url "http://127.0.0.1:8080"

echo ""
echo "✅ Sovereign System Fully Online"
echo "🌐 Dashboard: http://127.0.0.1:8080"
echo ""
