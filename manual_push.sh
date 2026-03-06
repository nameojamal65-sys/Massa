#!/data/data/com.termux/files/usr/bin/bash

# تنظيف أي بيانات عالقة (السر هنا)
git config --unset-all credential.helper
git config --global --unset-all credential.helper
git config --system --unset-all credential.helper

# إزالة الربط القديم
git remote remove origin

# إضافة الرابط الصحيح (بصيغة HTTPS القياسية)
git remote add origin https://github.com/nameojamal65-sys/Massa.git

echo -e "\033[1;32m[*] جاري الرفع الآن...\033[0m"
echo -e "\033[1;33m[!] عندما يطلب Username اكتب: nameojamal65-sys\033[0m"
echo -e "\033[1;33m[!] عندما يطلب Password الصق التوكن الخاص بك (ghp_...)\033[0m"

# تنفيذ الدفع
git push -u origin main --force
