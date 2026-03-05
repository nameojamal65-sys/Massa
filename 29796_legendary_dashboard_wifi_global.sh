#!/data/data/com.termux/files/usr/bin/bash
# ===============================================
# ⚡ Legendary Dashboard Hyper-Fast Wi-Fi Global
# ===============================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
PORT=9000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi Global..."

# البحث عن بورت فارغ تلقائيًا
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# الحصول على IP الجهاز على الشبكة
LOCAL_IP=$(ip addr show wlan0 | grep -Po 'inet \K[\d.]+')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="127.0.0.1"
fi

# وظيفة لتشغيل الإيجنت وإعادة التشغيل تلقائيًا إذا توقف
run_agent() {
    while true; do
        nohup python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
        AGENT_PID=$!
        sleep 2

        # تحقق من تشغيل البورت
        if lsof -i tcp:$PORT >/dev/null 2>&1; then
            echo "🚀 AI Agent مباشر ويعمل على $LOCAL_IP:$PORT"

            # افتح المتصفح تلقائيًا إن كان موجود
            if command -v termux-open-url >/dev/null 2>&1; then
                termux-open-url "http://$LOCAL_IP:$PORT"
            else
                echo "🔹 افتح الرابط في متصفحك: http://$LOCAL_IP:$PORT"
            fi

            break
        else
            echo "⚠️ فشل تشغيل الإيجنت، إعادة المحاولة تلقائيًا..."
            pkill -f python3 >/dev/null 2>&1
            sleep 2
        fi
    done
}

# تشغيل الإيجنت
run_agent

echo "🔹 لتتبع اللوج مباشرة: tail -f $LOG_FILE"
