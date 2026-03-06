#!/bin/bash
clear
echo "--- MASA FINAL DEPLOY: العنيد الذكي ---"

read -p "أدخل Render API Key: " API_KEY
echo "[*] جاري البحث عن الهوية (OwnerID)..."
OWNER_ID=$(curl -s -H "Authorization: Bearer $API_KEY" "https://api.render.com/v1/user" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "[✓] تم العثور على الهوية: $OWNER_ID"

read -p "اسم الخدمة: " NAME
read -p "رابط GitHub: " REPO

echo "[*] جاري إنشاء الخدمة..."

RESPONSE=$(curl -s -X POST "https://api.render.com/v1/services" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "web_service",
       "name": "'"$NAME"'",
       "ownerId": "'"$OWNER_ID"'",
       "repo": "'"$REPO"'",
       "serviceDetails": {
         "runtime": "node",
         "buildCommand": "npm install",
         "startCommand": "node src/index.js"
       }
     }')

echo $RESPONSE | jq .
