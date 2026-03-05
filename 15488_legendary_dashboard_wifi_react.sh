#!/data/data/com.termux/files/usr/bin/bash
# ========================================
# 🚀 Legendary Dashboard Full React Hyper-Fast
# ========================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"
PORT_AGENT=9000
PORT_FRONTEND=3000

# احصل على IP الواي فاي
IP=$(termux-wifi-connectioninfo | grep "ip" | awk '{print $2}')
echo "🌐 IP المحلي للجهاز: $IP"

# ===============================
# تشغيل AI Agent في الخلفية
# ===============================
pkill -f python3 >/dev/null 2>&1
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 &
disown
echo "✅ AI Agent يعمل على http://$IP:$PORT_AGENT"

# ===============================
# تشغيل React Frontend على IP الواي فاي
# ===============================
cd $FRONTEND_DIR
npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1
nohup npx serve -s build -l $PORT_FRONTEND --host $IP > $FRONTEND_LOG 2>&1 &
disown
echo "✅ Frontend Dashboard React جاهز على http://$IP:$PORT_FRONTEND"

# فتح المتصفح تلقائيًا على الجهاز نفسه (إذا متوفر)
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://$IP:$PORT_FRONTEND"
fi

echo "🌐 استخدم أي متصفح على نفس الشبكة للوصول إلى Dashboard React على http://$IP:$PORT_FRONTEND"
