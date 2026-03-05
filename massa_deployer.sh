#!/data/data/com.termux/files/usr/bin/bash

# الألوان
G='\033[1;32m' ; Y='\033[1;33m' ; B='\033[1;34m' ; R='\033[1;31m' ; N='\033[0m'

clear
echo -e "${B}=======================================${N}"
echo -e "${G}     MASA AI: محرك التشغيل السحابي      ${N}"
echo -e "${B}=======================================${N}"

# 1. طلب مفتاح API من الزعيم
echo -ne "${Y}[?] من فضلك الصق مفتاح Render API (يبدأ بـ rnd_): ${N}"
read RENDER_API_KEY

if [[ $RENDER_API_KEY != rnd_* ]]; then
    echo -e "${R}[!] خطأ: هذا ليس مفتاح API صحيح من Render.${N}"
    exit 1
fi

echo -e "${G}[*] جاري الاتصال بـ Render API...${N}"

# 2. استخراج المعرف الشخصي (Owner ID)
OWNER_ID=$(curl -s https://api.render.com/v1/owners \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  | jq -r '.[0].owner.id')

if [ "$OWNER_ID" == "null" ] || [ -z "$OWNER_ID" ]; then
    echo -e "${R}[!] فشل التحقق من المفتاح. تأكد من صلاحية المفتاح.${N}"
    exit 1
fi

echo -e "${G}[✓] تم التحقق من الهوية بنجاح: $OWNER_ID${N}"

# 3. إرسال أمر بناء الإمبراطورية (Blueprint Deployment)
echo -e "${Y}[*] جاري سحب مشروع MASSA من GitHub وتفعيله...${N}"

RESPONSE=$(curl -s -X POST https://api.render.com/v1/blueprint-resources \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "'$OWNER_ID'",
    "repo": "https://github.com/Rasan-co-sa/MASA_IMPERIAL_OS",
    "name": "MASA-IMPERIAL-SYSTEM"
  }')

# 4. النتيجة النهائية
if [[ $RESPONSE == *"id"* ]]; then
    echo -e "${B}=======================================${N}"
    echo -e "${G}    [✓] مبروك يا زعيم! ماسا الآن حية.    ${N}"
    echo -e "${G}    جاري الآن بناء السيرفر والواجهة.     ${N}"
    echo -e "${B}=======================================${N}"
    echo -e "${Y}يمكنك مراقبة التقدم من لوحة تحكم Render.${N}"
else
    echo -e "${R}[!] حدث خطأ أثناء الإرسال: $RESPONSE${N}"
fi
