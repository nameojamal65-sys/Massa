#!/bin/bash

# تحميل الإعدادات
if [ -f "deploy_config.sh" ]; then
    source deploy_config.sh
else
    echo "خطأ: ملف الإعدادات غير موجود. أنشئ deploy_config.sh أولاً."
    exit 1
fi

echo -e "\033[1;36m[*] جاري فحص حالة السيرفر ($SERVICE_ID)...\033[0m"

# جلب الحالة من رندر
RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services/$SERVICE_ID/deploys | grep -o '"status":"[^"]*"' | head -n 1)

if [ -z "$RESPONSE" ]; then
    echo -e "\033[1;31m[!] لم يتم استلام رد. تأكد من صحة الـ API_KEY والـ SERVICE_ID في ملف deploy_config.sh\033[0m"
else
    echo -e "\033[1;32m[✓] حالة السيرفر الحالية: $RESPONSE\033[0m"
fi

echo -e "\033[1;33m[*] هل تريد عمل Deploy جديد (y/n)؟\033[0m"
read choice

if [ "$choice" == "y" ]; then
    echo -e "\033[1;34m[*] جاري رفع الكود وإرسال أمر البناء...\033[0m"
    git add .
    git commit -m "Auto-Deploy $(date +%H:%M)"
    git push -u origin main --force
    curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys -H "Authorization: Bearer $API_KEY"
    echo -e "\033[1;32m[✓] تم إرسال أمر البناء بنجاح! تابعه من الموقع.\033[0m"
fi
