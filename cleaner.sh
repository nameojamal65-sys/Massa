#!/bin/bash

echo "--- Render Cleaner Pro ---"
read -p "أدخل الـ API Key الخاص برندر: " API_KEY

# جلب قائمة الخدمات
echo "[*] جاري جلب قائمة الخدمات..."
# طلب قائمة الخدمات من API رندر
curl -s -H "Authorization: Bearer $API_KEY" "https://api.render.com/v1/services" > raw_services.json

# استخراج المعرفات (ID)
grep -o '"id":"srv-[^"]*"' raw_services.json | cut -d'"' -f4 > services.list

if [ ! -s services.list ]; then
    echo "[!] لم يتم العثور على خدمات أو أن المفتاح غير صحيح."
    exit 1
fi

echo "[*] تم العثور على الخدمات التالية:"
cat -n services.list

# طلب تأكيد الحذف
read -p "أدخل رقم الخدمة التي تريد حذفها (أو 0 لحذف الجميع): " CHOICE

if [ "$CHOICE" == "0" ]; then
    echo "[!] جاري مسح جميع الخدمات..."
    for id in $(cat services.list); do
        echo "[*] جاري حذف الخدمة: $id"
        curl -X DELETE "https://api.render.com/v1/services/$id" -H "Authorization: Bearer $API_KEY"
    done
else
    SELECTED_ID=$(sed -n "${CHOICE}p" services.list)
    echo "[*] جاري حذف الخدمة المختارة: $SELECTED_ID"
    curl -X DELETE "https://api.render.com/v1/services/$SELECTED_ID" -H "Authorization: Bearer $API_KEY"
fi

echo "[✓] تمت العملية. تأكد من لوحة تحكم رندر!"
