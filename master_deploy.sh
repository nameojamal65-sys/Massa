#!/bin/bash

# --- إعدادات الماستر ---
# ضع المفتاح الخاص بك هنا فقط مرة واحدة
API_KEY="rnd_CPMtAJhgQ7WG8TB7sDaUCsYnlmmo"

echo -e "\033[1;36m[*] جاري فحص الاتصال بـ Render...\033[0m"

# استخراج الـ Service ID تلقائياً
SERVICE_ID=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services | grep -o '"id":"srv-[^"]*' | cut -d'"' -f4 | head -n 1)

if [ -z "$SERVICE_ID" ]; then
    echo -e "\033[1;31m[!] خطأ: لم يتم العثور على أي Service ID. تأكد من المفتاح!\033[0m"
    exit 1
fi

echo -e "\033[1;32m[+] تم العثور على الخدمة: $SERVICE_ID\033[0m"

echo -e "\033[1;33m[*] جاري رفع الكود لـ GitHub...\033[0m"
git add .
git commit -m "تحديث الماستر $(date +%H:%M)"
git push -u origin main --force

echo -e "\033[1;34m[*] جاري تنفيذ الـ Deploy في Render...\033[0m"
RESPONSE=$(curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"clearCache": "clear"}')

if [[ $RESPONSE == *"deploy"* ]]; then
    echo -e "\033[1;32m[✓] عظيم! تم إرسال أمر البناء بنجاح.\033[0m"
else
    echo -e "\033[1;31m[!] فشل الـ Deploy. رد رندر هو: $RESPONSE\033[0m"
fi
