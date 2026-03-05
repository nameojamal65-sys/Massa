#!/data/data/com.termux/files/usr/bin/bash
# ===============================
# 🚀 Legendary Dashboard Hyper-Fast Wi-Fi Auto Launcher
# ===============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
PORT=9000

echo "⏳ تحضير البورت وتشغيل المنظومة Hyper-Fast على Wi-Fi..."

# البحث عن بورت فارغ بسرعة
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "✅ البورت $PORT جاهز."

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# الحصول على IP المحلي تلقائيًا بطريقة متوافقة مع Termux
LOCAL_IP=$(python3 - <<END
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(("8.8.8.8", 80))
    print(s.getsockname()[0])
except:
    print("127.0.0.1")
finally:
    s.close()
END
)

# تشغيل الإيجنت في الخلفية مع nohup
nohup python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
disown

echo "🚀 AI Agent يعمل الآن على $LOCAL_IP:$PORT في الخلفية"
echo "🔹 لمتابعة اللوغ: tail -f $LOG_FILE"
