#!/data/data/com.termux/files/usr/bin/bash
# ==================================================
# 🚀 Legendary Dashboard Full React + Chat Hyper-Fast FANCY
# ==================================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"
PORT_AGENT=9000
PORT_FRONTEND=3000

# ===============================
# 🔹 تشغيل AI Agent في الخلفية
# ===============================
echo "⏳ تحضير البورت وتشغيل AI Agent..."
pkill -f python3 >/dev/null 2>&1
nohup python3 -u $AGENT_FILE $PORT_AGENT > $LOG_FILE 2>&1 &
disown
echo "✅ AI Agent يعمل الآن على localhost:$PORT_AGENT في الخلفية"

# ===============================
# 🔹 إعداد وتشغيل React Frontend مع شات فخم
# ===============================
echo "⏳ تحضير وتشغيل Frontend Dashboard..."
cd $FRONTEND_DIR
npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1
nohup npx serve -s build -l $PORT_FRONTEND > $FRONTEND_LOG 2>&1 &
disown
echo "✅ Frontend Dashboard فخم يعمل الآن على localhost:$PORT_FRONTEND"

# ===============================
# 🔹 فتح المتصفح تلقائيًا على نفس الجهاز
# ===============================
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:$PORT_FRONTEND"
fi

# ===============================
# 🔹 معلومات إضافية للمتابعة
# ===============================
echo "🔹 متابعة AI Agent لوغ: tail -f $LOG_FILE"
echo "🔹 متابعة Frontend لوغ: tail -f $FRONTEND_LOG"
echo "🌐 استخدم المتصفح على localhost:$PORT_FRONTEND للاستمتاع بالـ Dashboard الفخم"
