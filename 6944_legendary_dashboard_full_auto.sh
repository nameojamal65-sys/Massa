#!/bin/bash
# =========================================
# 🚀 Legendary Dashboard Hyper-Fast Auto Wi-Fi
# =========================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_AGENT="$SYSTEM_DIR/ai_agent.log"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FRONTEND="$SYSTEM_DIR/frontend.log"

PORT_AGENT=9000
PORT_FRONTEND=3000

echo "⏳ تحضير المنظومة Hyper-Fast كاملة..."

# =========================
# 1️⃣ تشغيل AI Agent في الخلفية
# =========================
pkill -f python3 >/dev/null 2>&1
while lsof -i tcp:$PORT_AGENT >/dev/null 2>&1; do
    PORT_AGENT=$((PORT_AGENT+1))
done
echo "✅ البورت $PORT_AGENT جاهز للإيجنت"

nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_AGENT 2>&1 &
disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT_AGENT في الخلفية"
echo "🔹 متابعة اللوغ: tail -f $LOG_AGENT"

# =========================
# 2️⃣ اكتشاف IP محلي على Wi-Fi تلقائي
# =========================
IP_LOCAL=$(hostname -I | awk '{print $1}')
echo "🌐 IP المحلي للجهاز: $IP_LOCAL"

# =========================
# 3️⃣ تشغيل React Frontend Dashboard
# =========================
mkdir -p $FRONTEND_DIR

# تثبيت Node إذا لم يكن موجود
if ! command -v npm >/dev/null 2>&1; then
    echo "📦 تثبيت Node.js..."
    sudo apt update && sudo apt install -y nodejs npm
fi

cd $FRONTEND_DIR
npm install >/dev/null 2>&1

nohup npm start > $LOG_FRONTEND 2>&1 &
disown
echo "🚀 Frontend Dashboard فخم يعمل الآن على http://$IP_LOCAL:$PORT_FRONTEND"
echo "🔹 متابعة اللوغ: tail -f $LOG_FRONTEND"
