#!/bin/bash
# 🚀 سكربت تشغيل Sovereign Control Center على الإنترنت باستخدام Ngrok

# إعدادات
SOVEREIGN_SCRIPT="sovereign_control_center.py"
DEFAULT_PORT=9000

# تحقق من وجود Ngrok
if ! [ -x "$(command -v ngrok)" ]; then
    echo "⚠️ لم يتم العثور على Ngrok، جاري التثبيت..."
    pkg install wget unzip -y
    wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip
    unzip ngrok-stable-linux-arm.zip
    chmod +x ngrok
fi

# التحقق من وجود سكربت Sovereign
if [ ! -f "$SOVEREIGN_SCRIPT" ]; then
    echo "⚠️ خطأ: لم يتم العثور على $SOVEREIGN_SCRIPT في هذا المجلد!"
    exit 1
fi

# اختيار بورت تلقائي (9000 أو أي بورت متاح)
PORT=$DEFAULT_PORT
while lsof -i:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "🚀 تشغيل Sovereign Control Center على البورت: $PORT"

# تشغيل السيرفر في الخلفية
python3 $SOVEREIGN_SCRIPT $PORT &
PID=$!

# إعطاء وقت للسكريبت ليشتغل
sleep 2

# تشغيل Ngrok على نفس البورت
./ngrok http $PORT &
NGROK_PID=$!

# انتظار انتهاء السكربت
echo "🌐 الوصول للمنظومة عبر الإنترنت..."
sleep 2
# الحصول على الرابط العام من Ngrok
curl --silent http://127.0.0.1:4040/api/tunnels | grep -o 'https://[0-9a-z]*\.ngrok.io'

# إبقاء السكربت شغال
wait $PID
