#!/bin/bash

# إذا لم يكن المفتاح محفوظاً، اسأل عنه
if [ -z "$API_KEY" ]; then
    echo -e "\033[1;36m[?] يرجى لصق الـ API KEY (الذي يبدأ بـ rnd_): \033[0m"
    read -r API_KEY
fi

echo -e "\033[1;36m[*] جاري البحث عن الـ Service ID الخاص بك...\033[0m"

# جلب أول Service ID متاح في حسابك تلقائياً
SERVICE_ID=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/services | grep -o '"id":"srv-[^"]*' | cut -d'"' -f4 | head -n 1)

if [ -z "$SERVICE_ID" ]; then
    echo -e "\033[1;31m[!] خطأ: لم يتم العثور على أي خدمة! تأكد من أن المفتاح صحيح.\033[0m"
    exit 1
fi

echo -e "\033[1;32m[+] تم العثور على الخدمة: $SERVICE_ID\033[0m"

echo -e "\033[1;33m[*] هل تريد رفع الكود وعمل Deploy جديد (y/n)؟\033[0m"
read -r choice

if [ "$choice" == "y" ]; then
    echo -e "\033[1;34m[*] جاري الرفع لـ GitHub...\033[0m"
    git add .
    git commit -m "Auto-Deploy $(date +%H:%M)"
    git push -u origin main --force
    
    echo -e "\033[1;34m[*] جاري إرسال أمر البناء لـ Render...\033[0m"
    RESPONSE=$(curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys -H "Authorization: Bearer $API_KEY")
    
    echo -e "\033[1;32m[✓] تم الإرسال! رد السيرفر: \033[0m"
    echo $RESPONSE
fi
