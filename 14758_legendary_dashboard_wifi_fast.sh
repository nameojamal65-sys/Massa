#!/data/data/com.termux/files/usr/bin/bash

# 🏎️ Legendary Dashboard Hyper-Fast Wi-Fi Launcher

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
PORT=9000
LOG_FILE="$SYSTEM_DIR/ai_agent.log"

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ بسرعة
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة فورًا
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت ومراقبته
while true; do
    python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
    AGENT_PID=$!
    sleep 1

    # تحقق من تشغيل الإيجنت على البورت
    if lsof -i tcp:$PORT >/dev/null 2>&1; then
        echo "🚀 AI Agent مباشر على الإنترنت ويعمل على Wi-Fi IP: $(ip route get 1.1.1.1 | awk '{print $7; exit}'):$PORT"
        echo "🔹 لمتابعة اللوج: tail -f $LOG_FILE"
        break
    else
        pkill -f python3 >/dev/null 2>&1
        sleep 1
    fi
done
