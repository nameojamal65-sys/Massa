#!/data/data/com.termux/files/usr/bin/bash
# 🔹 تشغيل Sovereign Control Center بأمان على أي بورت فارغ

cd ~/Legendary_Dashboard || exit

# البحث عن بورت فارغ ابتداءً من 9000 وحتى 9100
PORT=9000
MAX_PORT=9100
while lsof -i:$PORT &>/dev/null; do
    PORT=$((PORT+1))
    if [ $PORT -gt $MAX_PORT ]; then
        echo "⚠️ لم يتم العثور على أي بورت فارغ بين 9000 و 9100"
        exit 1
    fi
done

echo "🚀 تشغيل Sovereign Control Center على البورت: $PORT"

# تشغيل السيرفر في الخلفية مع تمرير البورت
python3 sovereign_control_center_new.py $PORT &

# الانتظار ثانيتين حتى يبدأ السيرفر
sleep 2

# فتح المتصفح على الـ Dashboard تلقائيًا
termux-open "http://127.0.0.1:$PORT/index.html"
