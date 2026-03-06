#!/bin/bash
source ../deploy_config.sh
SERVICE_ID="srv-d6l33h9aae7s73fufir0"

echo -e "\033[1;36m[*] فحص ملفات المشروع...\033[0m"
if [ -f "package.json" ]; then
    echo -e "\033[1;32m[✓] ملف package.json موجود.\033[0m"
else
    echo -e "\033[1;31m[!] تنبيه: ملف package.json مفقود! هذا هو السبب الرئيسي لفشل البناء.\033[0m"
fi

echo -e "\033[1;36m[*] جلب سجلات الخطأ الأخيرة من رندر...\033[0m"
# جلب سجلات البناء الفاشل
ERROR_LOG=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services/$SERVICE_ID/deploys?limit=1 | grep -o '"status":"build_failed"')

if [ -n "$ERROR_LOG" ]; then
    echo -e "\033[1;31m[!] النتيجة: البناء لا يزال فاشلاً (Build Failed).\033[0m"
    echo -e "\033[1;33m[?] نصيحة: تأكد من إعدادات الـ Root Directory في موقع رندر.\033[0m"
else
    echo -e "\033[1;32m[✓] لا يوجد خطأ بناء في آخر محاولة.\033[0m"
fi
