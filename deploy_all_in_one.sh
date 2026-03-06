#!/bin/bash

# 1. إعداد المسارات
echo -e "\033[1;36m[*] جاري تجميع الملفات في المسار الرئيسي...\033[0m"
mv MASA_DEPLOY_MASTER/* . 2>/dev/null
mv MASA_DEPLOY_MASTER/.* . 2>/dev/null

# 2. التأكد من وجود ملف الهوية
if [ ! -f "package.json" ]; then
    echo -e "\033[1;33m[!] جاري إنشاء package.json افتراضي...\033[0m"
    echo '{"name": "massa-bot", "version": "1.0.0", "scripts": {"start": "node index.js"}}' > package.json
fi

# 3. رفع الملفات لـ GitHub
echo -e "\033[1;34m[*] جاري الرفع لـ GitHub...\033[0m"
git add .
git commit -m "All-In-One Auto Deploy: $(date +%H:%M)"
git push origin main

# 4. إرسال أمر البناء لـ Render
if [ -f "deploy_config.sh" ]; then
    source deploy_config.sh
    SERVICE_ID="srv-d6l33h9aae7s73fufir0"
    echo -e "\033[1;34m[*] إرسال أمر البناء لـ Render...\033[0m"
    curl -s -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys -H "Authorization: Bearer $API_KEY"
    echo -e "\033[1;32m[✓] تمت المهمة بنجاح! السيرفر يبني الآن.\033[0m"
else
    echo -e "\033[1;31m[!] خطأ: ملف deploy_config.sh مفقود!\033[0m"
fi
