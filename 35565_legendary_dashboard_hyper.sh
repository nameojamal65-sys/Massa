#!/data/data/com.termux/files/usr/bin/bash

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent_hyper.log"
PORT=9000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast..."

# البحث عن بورت فارغ سريع
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة فورًا
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت ومراقبته تلقائيًا مع Auto-Fix Hyper
while true; do
    python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
    AGENT_PID=$!
    sleep 0.5

    if lsof -i tcp:$PORT >/dev/null 2>&1; then
        echo "🚀 AI Agent مباشر ويعمل على localhost:$PORT"
        wait $AGENT_PID
    else
        echo "⚠️ فشل تشغيل الإيجنت، إعادة المحاولة تلقائيًا..."
        pkill -f python3 >/dev/null 2>&1
        sleep 0.5
    fi
done
