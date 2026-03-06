#!/bin/bash

# 1. تحميل المفتاح من الملف الموجود في المجلد الرئيسي
if [ -f "../deploy_config.sh" ]; then
    source ../deploy_config.sh
elif [ -f "deploy_config.sh" ]; then
    source deploy_config.sh
else
    echo -e "\033[1;31m[!] ملف deploy_config.sh غير موجود. شغل سكربت deploy_setup.sh أولاً.\033[0m"
    exit 1
fi

echo -e "\033[1;36m[*] جاري البحث عن الخدمة الحقيقية في حسابك...\033[0m"

# 2. جلب الـ ID الصحيح تلقائياً باستخدام المفتاح
SERVICE_ID=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services | grep -o '"id":"srv-[^"]*' | cut -d'"' -f4 | head -n 1)

if [ -z "$SERVICE_ID" ]; then
    echo -e "\033[1;31m[!] لم نجد أي خدمة. تأكد من المفتاح rnd_.\033[0m"
    exit 1
fi

echo -e "\033[1;32m[✓] تم العثور على الخدمة: $SERVICE_ID\033[0m"

# 3. التحقق من الحالة
RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services/$SERVICE_ID/deploys | grep -o '"status":"[^"]*"' | head -n 1)
echo -e "\033[1;32m[✓] الحالة الحالية: $RESPONSE\033[0m"

echo -e "\033[1;33m[*] هل تريد عمل Deploy جديد (y/n)؟\033[0m"
read choice

if [ "$choice" == "y" ]; then
    echo -e "\033[1;34m[*] جاري رفع التعديلات...\033[0m"
    git add .
    git commit -m "Auto-Deploy $(date +%H:%M)"
    git push -u origin main --force
    
    echo -e "\033[1;34m[*] إرسال أمر البناء للـ ID الصحيح...\033[0m"
    curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys -H "Authorization: Bearer $API_KEY"
    echo -e "\033[1;32m[✓] تم الإرسال بنجاح للخدمة الصحيحة!\033[0m"
fi
