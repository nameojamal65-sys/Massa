#!/data/data/com.termux/files/usr/bin/bash
# =============================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi Auto Launcher
# =============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
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

# التأكد من تشغيل الإيجنت
sleep 2

echo "🚀 AI Agent يعمل الآن على localhost:$PORT في الخلفية"

# محاولة معرفة IP الجهاز على شبكة الواي فاي
LOCAL_IP=$(ip addr show wlan0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="localhost"
fi

echo "🌐 IP المحلي للجهاز: $LOCAL_IP"

# فتح الداشبورد تلقائيًا في المتصفح (Termux يدعم am start)
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://$LOCAL_IP:$PORT"
fi

echo "🔹 لمتابعة اللوغ: tail -f $LOG_FILE"
