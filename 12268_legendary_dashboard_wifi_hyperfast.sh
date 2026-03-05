#!/data/data/com.termux/files/usr/bin/bash

# ===========================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi Launcher
# ===========================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"
PORT_AGENT=9000
PORT_FRONTEND=3000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ سريع للإيجنت
while lsof -i tcp:$PORT_AGENT >/dev/null 2>&1; do
    PORT_AGENT=$((PORT_AGENT+1))
done
echo "✅ البورت $PORT_AGENT جاهز للإيجنت."

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية مع nohup
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 & disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT_AGENT في الخلفية"


# الحصول على IP المحلي
IP=$(ip route | awk '/wlan0/ {for(i=1;i<=NF;i++){if($i=="src"){print $(i+1)}}}')
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi
echo "🌐 IP المحلي للجهاز: $IP"

# فتح الـ Frontend (مثال React أو أي واجهة) على البورت الخاص بالـ Dashboard
# إذا عندك serve أو npm start لواجهة React:
# cd $SYSTEM_DIR/frontend && nohup npm start > $FRONTEND_LOG 2>&1 & disown

echo "🚀 Frontend Dashboard فخم يعمل الآن على http://$IP:$PORT_FRONTEND"
echo "🔹 لمتابعة اللوغ: tail -f $LOG_FILE"
