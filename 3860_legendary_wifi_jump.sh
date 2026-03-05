#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Legendary Dashboard – WiFi Jump

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"
PORT_AGENT=9000
PORT_FRONTEND=3000

# تشغيل AI Agent
pkill -f python3 >/dev/null 2>&1
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 &
disown
echo "✅ AI Agent يعمل على localhost:$PORT_AGENT"

# تشغيل React Frontend
cd $FRONTEND_DIR
npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1
nohup npx serve -s build -l $PORT_FRONTEND > $FRONTEND_LOG 2>&1 &
disown
echo "✅ Frontend React يعمل على localhost:$PORT_FRONTEND"

# احصل على IP الواي فاي الحالي
IP=$(termux-wifi-connectioninfo | grep "ip" | awk '{print $2}')

# افتح المتصفح تلقائيًا على نفس الجهاز
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://$IP:$PORT_FRONTEND"
fi

echo "🌐 المنظومة Hyper-Fast متاحة على الشبكة: http://$IP:$PORT_FRONTEND"
