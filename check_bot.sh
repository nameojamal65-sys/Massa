#!/bin/bash
echo -e "\033[1;36m[*] بدء الفحص العميق للبوت...\033[0m"

# 1. فحص كود index.js
if [ -s "index.js" ]; then
    echo -e "\033[1;32m[✓] ملف index.js يحتوي على كود (غير فارغ).\033[0m"
else
    echo -e "\033[1;31m[!] خطأ: ملف index.js فارغ أو غير موجود!\033[0m"
fi

# 2. فحص المكتبات الأساسية في package.json
if grep -q "dependencies" package.json; then
    echo -e "\033[1;32m[✓] هناك مكتبات محددة في package.json.\033[0m"
else
    echo -e "\033[1;33m[!] تنبيه: لا توجد dependencies في package.json. هل البوت يحتاج مكتبات (مثل discord.js)؟\033[0m"
fi

# 3. فحص التشغيل (تجريبي)
echo -e "\033[1;36m[*] محاولة تشغيل البوت لمدة 3 ثوانٍ للتأكد من عدم وجود أخطاء فادحة...\033[0m"
node index.js &
PID=$!
sleep 3
if ps -p $PID > /dev/null; then
    echo -e "\033[1;32m[✓] البوت يعمل بشكل طبيعي حالياً.\033[0m"
    kill $PID
else
    echo -e "\033[1;31m[!] خطأ: البوت انطفأ فوراً (Crash/Exit).\033[0m"
fi
