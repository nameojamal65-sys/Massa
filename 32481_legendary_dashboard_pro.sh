#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# 🚀 Legendary Dashboard – Production WiFi
# ==========================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"

PORT_AGENT=9000
PORT_FRONTEND=3000

echo "========================================="
echo "🚀 تشغيل Legendary Dashboard (Production)"
echo "========================================="

# ------------------------------------------
# استخراج IP عبر termux-api (إن وجد)
# ------------------------------------------
if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
    IP=$(termux-wifi-connectioninfo 2>/dev/null | sed -n 's/.*"ip":"\([^"]*\)".*/\1/p')
fi

# fallback
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi

echo "🌐 IP المحلي: $IP"

# ------------------------------------------
# إيقاف أي عمليات قديمة
# ------------------------------------------
pkill -f python3 >/dev/null 2>&1
pkill -f react-scripts >/dev/null 2>&1
pkill -f serve >/dev/null 2>&1

# ------------------------------------------
# تشغيل AI Agent
# ------------------------------------------
echo "🚀 تشغيل AI Agent..."
nohup python3 -u "$AGENT_FILE" "$PORT_AGENT" > "$LOG_FILE" 2>&1 &
disown
sleep 1
echo "✅ AI Agent يعمل على http://$IP:$PORT_AGENT"

# ------------------------------------------
# تشغيل React Production Build
# ------------------------------------------
echo "⏳ تجهيز React Frontend..."
cd "$FRONTEND_DIR" || exit 1

npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1

nohup npx serve -s build -l 0.0.0.0:$PORT_FRONTEND > "$FRONTEND_LOG" 2>&1 &
disown
sleep 2

echo "✅ Frontend جاهز على:"
echo "   👉 http://$IP:$PORT_FRONTEND"
echo "   👉 http://localhost:$PORT_FRONTEND"

# ------------------------------------------
# فتح المتصفح تلقائياً على الجهاز نفسه
# ------------------------------------------
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:$PORT_FRONTEND" >/dev/null 2>&1
fi

echo ""
echo "🔥 النظام يعمل الآن بوضع Production!"
echo "📄 AI Log: tail -f $LOG_FILE"
echo "📄 Frontend Log: tail -f $FRONTEND_LOG"
echo "========================================="
