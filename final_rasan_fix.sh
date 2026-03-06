#!/data/data/com.termux/files/usr/bin/bash

# الألوان
G='\033[1;32m' ; B='\033[1;34m' ; Y='\033[1;33m' ; N='\033[0m'

KEY="rnd_9ui0cDvF48MUK7yb1IKctBHvInjV"
ID="srv-d55if2a4d50c73a0ama0"

echo -e "${B}[*] جاري ضبط الإعدادات بناءً على مستودع Rasan...${N}"

# تحديث رابط المستودع إلى الرابط الجديد في الصورة
NEW_REPO="https://github.com/rasan-co-sa/Rasan"

curl -s -X PATCH https://api.render.com/v1/services/$ID \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"repo\": \"$NEW_REPO\",
    \"serviceDetails\": {
      \"buildCommand\": \"chmod +x run_fast.sh\",
      \"startCommand\": \"./run_fast.sh\"
    }
  }" > /dev/null

echo -e "${G}[✓] تم تحديث المستودع وأمر التشغيل!${N}"

# بدء بناء جديد
echo -e "${Y}[*] جاري إطلاق بناء جديد (Deploy)...${N}"
curl -s -X POST https://api.render.com/v1/services/$ID/deploys \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" > /dev/null

echo -e "${B}🚀 تمت العملية. راقب الآن بالرادار: ./monitor.sh${N}"
