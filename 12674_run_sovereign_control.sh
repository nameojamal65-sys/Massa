#!/bin/bash

# 🔹 اسم السكربت الجديد
SCRIPT="sovereign_control_center_new.py"

# 🔹 تأكد من وجود السكربت
if [ ! -f "$SCRIPT" ]; then
    echo "⚠️ لم يتم العثور على $SCRIPT في هذا المجلد!"
    exit 1
fi

# 🔹 اعطاء صلاحيات التنفيذ للسكربت
chmod +x "$SCRIPT"
echo "✅ تم إعطاء صلاحيات التنفيذ للسكربت."

# 🔹 تحديد البورت الافتراضي
PORT=9000

# 🔹 التحقق إذا كان البورت مشغول
if lsof -i:$PORT > /dev/null; then
    echo "⚠️ البورت $PORT مشغول! البحث عن بورت فارغ..."
    PORT=$(comm -23 <(seq 9000 9100) <(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d: -f2) | head -n 1)
    echo "🔹 سيتم استخدام البورت $PORT"
fi

# 🔹 تشغيل السكربت
echo "🚀 جاري تشغيل $SCRIPT على البورت $PORT ..."
python3 "$SCRIPT" $PORT &

# 🔹 فتح المتصفح تلقائيًا على الـ Dashboard
sleep 2
termux-open "http://127.0.0.1:$PORT/index.html"
