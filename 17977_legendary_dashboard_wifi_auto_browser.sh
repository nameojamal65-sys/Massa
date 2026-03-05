#!/data/data/com.termux/files/usr/bin/bash
# ================================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi + Auto Browser
# ================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"
PORT_AGENT=9000
PORT_FRONTEND=3000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ للإيجنت
while lsof -i tcp:$PORT_AGENT >/dev/null 2>&1; do
    PORT_AGENT=$((PORT_AGENT+1))
done

echo "✅ البورت $PORT_AGENT جاهز للإيجنت."

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية مع nohup
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 &
disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT_AGENT في الخلفية"

# تشغيل Frontend React Dashboard
# هنا نفترض أنك شغلت React server على PORT_FRONTEND
# أو ممكن تستخدم serve/build إن كان جاهز
nohup npm --prefix $SYSTEM_DIR/frontend start > $FRONTEND_LOG 2>&1 &
disown
echo "🚀 Frontend Dashboard جاهز على http://localhost:$PORT_FRONTEND"

# معرفة IP المحلي للجهاز (للوصول من جهاز آخر)
IP=$(termux-wifi-connectioninfo | grep ip | awk -F'"' '{print $4}')
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi
echo "🌐 IP المحلي للجهاز: $IP"

# فتح المتصفح تلقائيًا على الواجهة
termux-open-url "http://$IP:$PORT_FRONTEND"

# متابعة اللوغ
echo "🔹 متابعة لوغ الإيجنت: tail -f $LOG_FILE"
echo "🔹 متابعة لوغ Frontend: tail -f $FRONTEND_LOG"
