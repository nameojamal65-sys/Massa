#!/bin/bash
# مركز الإنشاء القسري
read -p "أدخل Render API Key: " API_KEY
read -p "أدخل اسم الخدمة الجديد: " NAME
read -p "أدخل رابط مستودع GitHub (مثلاً https://github.com/name/repo): " REPO

echo "[*] جاري إنشاء الخدمة في رندر..."

RESPONSE=$(curl -s -X POST "https://api.render.com/v1/services" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "web",
       "name": "'"$NAME"'",
       "runtime": "node",
       "repo": "'"$REPO"'",
       "serviceDetails": {
         "buildCommand": "npm install",
         "startCommand": "node src/index.js"
       }
     }')

echo "[✓] تم الإرسال. الرد من رندر:"
echo $RESPONSE | jq .  # تأكد أنك مثبت jq (pkg install jq)
