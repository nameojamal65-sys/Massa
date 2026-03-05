#!/data/data/com.termux/files/usr/bin/bash
# =============================
# ⚡ Legendary Dashboard Wi-Fi Full Launcher
# =============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
PORT=9000
LOG_FILE="$SYSTEM_DIR/ai_agent.log"

echo "⏳ تحضير البورت وتشغيل المنظومة الكاملة على Wi-Fi..."

# البحث عن بورت فارغ
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    echo "⚠️ البورت $PORT مستخدم، تجربة البورت التالي..."
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت ومراقبته تلقائيًا
while true; do
    python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
    AGENT_PID=$!
    sleep 1

    if lsof -i tcp:$PORT >/dev/null 2>&1; then
        IP=$(ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
        echo "🚀 AI Agent مباشر ويعمل على Wi-Fi على IP: $IP:$PORT"
        echo "🔹 لمتابعة اللوج: tail -f $LOG_FILE"

        # فتح المتصفح تلقائيًا إذا متاح (Termux يدعم am start)
        if command -v am >/dev/null 2>&1; then
            am start -a android.intent.action.VIEW -d "http://$IP:$PORT"
        fi

        # الانتظار حتى يتوقف الإيجنت لإعادة تشغيله
        wait $AGENT_PID
    else
        echo "⚠️ فشل تشغيل الإيجنت، إعادة المحاولة تلقائيًا..."
        pkill -f python3 >/dev/null 2>&1
        sleep 1
    fi
done
