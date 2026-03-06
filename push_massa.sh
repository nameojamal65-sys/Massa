#!/data/data/com.termux/files/usr/bin/bash

# --- ضع بياناتك هنا ---
USER="nameojamal65-sys"
TOKEN="ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
REPO="Massa"
# ---------------------

URL="https://$USER:$TOKEN@github.com/$USER/$REPO.git"

echo -e "\033[1;34m[*] جاري ربط المستودع باسم المستخدم: $USER\033[0m"

# إزالة أي ربط قديم
git remote remove origin 2>/dev/null

# إضافة الرابط الجديد بالتوكن
git remote add origin $URL

# الرفع القسري
echo -e "\033[1;32m[*] جاري الدفع (Push) إلى GitHub...\033[0m"
git push -u origin main --force

if [ $? -eq 0 ]; then
    echo -e "\033[1;32m[✓] تم رفع الملفات بنجاح! رندر سيبدأ البناء الآن.\033[0m"
else
    echo -e "\033[1;31m[!] فشل الرفع. تأكد من التوكن وصلاحياته.\033[0m"
fi
