#!/data/data/com.termux/files/usr/bin/bash
# ===============================
# 🚀 Legendary Dashboard React + AI Agent
# ===============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
BACKEND_FILE="$SYSTEM_DIR/backend/ai_agent_online.py"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"

# ======= تحضير البورتات =======
PORT_BACKEND=9000
PORT_FRONTEND=3000

# البحث عن بورت فارغ للـ Backend
while lsof -i tcp:$PORT_BACKEND >/dev/null 2>&1; do
    PORT_BACKEND=$((PORT_BACKEND+1))
done

# البحث عن بورت فارغ للـ Frontend
while lsof -i tcp:$PORT_FRONTEND >/dev/null 2>&1; do
    PORT_FRONTEND=$((PORT_FRONTEND+1))
done

echo "✅ البورت Backend جاهز: $PORT_BACKEND"
echo "✅ البورت Frontend جاهز: $PORT_FRONTEND"

# ======= قتل أي عملية بايثون عالقة =======
pkill -f python3 >/dev/null 2>&1

# ======= تشغيل الـ Backend AI Agent في الخلفية =======
nohup python3 -u $BACKEND_FILE $PORT_BACKEND > $LOG_FILE 2>&1 &
disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT_BACKEND في الخلفية"
echo "🔹 متابعة اللوغ: tail -f $LOG_FILE"

# ======= تشغيل Frontend React =======
cd $FRONTEND_DIR
if [ ! -d "node_modules" ]; then
    echo "⏳ تثبيت الحزم للواجهة..."
    npm install
fi

nohup npm start > $FRONTEND_LOG 2>&1 &
disown
echo "🚀 Frontend Dashboard فخم يعمل الآن على localhost:$PORT_FRONTEND"
echo "🔹 متابعة Frontend لوغ: tail -f $FRONTEND_LOG"

# ======= IP محلي للواي فاي =======
IP=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi
echo "🌐 IP المحلي للجهاز: $IP"
echo "🌐 للوصول للواجهة افتح: http://$IP:$PORT_FRONTEND"
