#!/bin/bash

echo -e "\033[1;36m[!] أهلاً بك يا زعيم، جاري إعداد سكربت النشر التلقائي...\033[0m"

# طلب البيانات من المستخدم
read -p "أدخل الـ API Key الخاص بـ Render (يبدأ بـ rnd_): " API_KEY
read -p "أدخل الـ Service ID (تأكد أنه يبدأ بـ srv-): " SERVICE_ID

echo -e "\033[1;33m[*] جاري رفع الكود إلى GitHub...\033[0m"
git add .
git commit -m "تحديث تلقائي من Termux"
git push -u origin main --force

echo -e "\033[1;32m[*] جاري إرسال أمر البناء إلى Render...\033[0m"
RESPONSE=$(curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"clearCache": "clear"}')

echo -e "\033[1;34m[✓] استجابة السيرفر: $RESPONSE\033[0m"
echo -e "\033[1;32m[✓] تمت العملية بنجاح! راقب الـ Logs في رندر.\033[0m"
