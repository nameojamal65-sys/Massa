#!/bin/bash
clear
echo "--- MASA ULTIMATE DEPLOY MASTER (FORCE MODE) ---"

read -p "أدخل Render API Key: " API_KEY
read -p "أدخل اسم الخدمة الجديد: " NAME
read -p "أدخل رابط مستودع GitHub: " REPO

echo "[*] جاري محاولة إنشاء الخدمة..."

RESPONSE=$(curl -s -X POST "https://api.render.com/v1/services" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "web",
       "name": "'"$NAME"'",
       "repo": "'"$REPO"'",
       "serviceDetails": {
         "runtime": "node",
         "buildCommand": "npm install",
         "startCommand": "node src/index.js"
       }
     }')

echo "[*] رد رندر:"
echo $RESPONSE | jq .

# استخراج الـ ID للخدمة
SERVICE_ID=$(echo $RESPONSE | grep -o '"id":"srv-[^"]*"' | cut -d'"' -f4)
if [ ! -z "$SERVICE_ID" ]; then
    echo $SERVICE_ID > .service_id
    echo "[✓] تم الإنشاء بنجاح! الـ ID هو: $SERVICE_ID"
fi
