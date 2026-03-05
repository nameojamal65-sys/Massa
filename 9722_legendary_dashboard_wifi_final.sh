#!/data/data/com.termux/files/usr/bin/bash
# ===============================================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi Local
# ===============================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"

# بورت AI Agent
PORT_AGENT=9000
# بورت Frontend
PORT_FRONTEND=3000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ لـ AI Agent
while lsof -i tcp:$PORT_AGENT >/dev/null 2>&1; do
    PORT_AGENT=$((PORT_AGENT+1))
done
echo "✅ البورت $PORT_AGENT جاهز للإيجنت."

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل AI Agent في الخلفية
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 &
disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT_AGENT في الخلفية"

# تشغيل Frontend Dashboard (نفترض React أو Node server)
nohup npx serve -s $SYSTEM_DIR/frontend -l $PORT_FRONTEND > $FRONTEND_LOG 2>&1 &
disown
echo "🚀 Frontend Dashboard جاهز على http://127.0.0.1:$PORT_FRONTEND"

# متابعة اللوغات
echo "🔹 لمتابعة اللوغ: tail -f $LOG_FILE"
echo "🔹 لمتابعة Frontend لوغ: tail -f $FRONTEND_LOG"
