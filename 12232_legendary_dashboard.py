#!/data/data/com.termux/files/usr/bin/bash

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
PORT=9000
LOG_FILE="$SYSTEM_DIR/ai_agent.log"

echo "⏳ تحضير البورت وتشغيل المنظومة بسرعة قصوى..."

# البحث عن بورت فارغ بسرعة
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عمليات بايثون عالقة فورًا
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت ومراقبته تلقائيًا
while true; do
    python3 $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
    AGENT_PID=$!
    sleep 1

    if lsof -i tcp:$PORT >/dev/null 2>&1; then
        echo "🚀 AI Agent مباشر ويعمل على localhost:$PORT"
        break
    else
        pkill -f python3 >/dev/null 2>&1
        sleep 1
    fi
done

# إبقاء السكربت شغال لمراقبة الإيجنت
wait $AGENT_PID
