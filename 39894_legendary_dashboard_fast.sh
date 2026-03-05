#!/data/data/com.termux/files/usr/bin/bash

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
PORT=9000
LOG_FILE="$SYSTEM_DIR/ai_agent.log"

echo "⏳ تحضير البورت وتشغيل الإيجنت في الخلفية..."

# التأكد من أن البورت فارغ
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    echo "⚠️ البورت $PORT مستخدم، تجربة البورت التالي..."
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي بايثون عالق
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية باستخدام nohup
nohup python3 "$AGENT_FILE" $PORT >> "$LOG_FILE" 2>&1 &

echo "🚀 AI Agent يعمل الآن على localhost:$PORT"
echo "🔹 لمتابعة اللوج: tail -f $LOG_FILE"
