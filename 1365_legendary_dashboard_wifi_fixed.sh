#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi (FIXED)

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
PORT=9000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية
nohup python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
disown

LOCAL_IP=$(ip addr show wlan0 | grep -Po 'inet \K[\d.]+')
[ -z "$LOCAL_IP" ] && LOCAL_IP="127.0.0.1"

echo "🚀 AI Agent يعمل الآن على $LOCAL_IP:$PORT في الخلفية"
echo "🔹 لمتابعة اللوج: tail -f $LOG_FILE"
