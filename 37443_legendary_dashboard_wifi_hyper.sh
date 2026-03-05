#!/data/data/com.termux/files/usr/bin/bash
# =============================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi Launcher
# =============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
PORT=9000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ بسرعة
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done

echo "✅ البورت $PORT جاهز."

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية مع nohup
nohup python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
disown

# الحصول على IP الجهاز على الواي فاي
IP=$(ip -o -4 addr list wlan0 | awk '{print $4}' | cut -d/ -f1 2>/dev/null)
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi

echo "🌐 IP المحلي للجهاز: $IP"
echo "🚀 AI Agent يعمل الآن على $IP:$PORT في الخلفية"
echo "🔹 لمتابعة اللوغ: tail -f $LOG_FILE"

# تشغيل باك إند الداشبورد
nohup python3 -u $SYSTEM_DIR/ai_agent_dashboard.py > $SYSTEM_DIR/dashboard.log 2>&1 &
disown

echo "🌐 افتح المتصفح على: http://$IP:$PORT"
