#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/Legendary_Dashboard/v6"
BACK="$BASE/backend"
FRONT="$BASE/frontend"
PORT=9000
FRONT_PORT=3000

# 🛑 إيقاف أي نسخ سابقة
pkill -f uvicorn >/dev/null 2>&1
pkill -f python3 -m http.server >/dev/null 2>&1

# 🌐 احصل على IP من الواي فاي بدقة
IP=$(termux-wifi-connectioninfo | grep -oP '"ip":"\K[^"]+')

# 🚀 تشغيل Backend
echo "🚀 تشغيل Backend..."
cd $BACK
nohup uvicorn main:app --host 0.0.0.0 --port $PORT > backend.log 2>&1 &
disown

# 🚀 تشغيل Frontend React
echo "🌐 تشغيل Frontend..."
cd $FRONT
nohup python3 -m http.server $FRONT_PORT > frontend.log 2>&1 &
disown

# ⏱ انتظر قليلًا لإقلاع السيرفرات
sleep 2

# 🌐 فتح المتصفح تلقائيًا إذا متاح
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://$IP:$FRONT_PORT"
fi

# ✅ تقرير الحالة النهائي
echo "🔥 Legendary v6 FullStack WiFi Jump Ready"
echo "Backend: http://$IP:$PORT"
echo "Frontend: http://$IP:$FRONT_PORT"
echo "=============================="
