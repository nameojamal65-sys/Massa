#!/data/data/com.termux/files/usr/bin/bash

# الألوان
G='\033[1;32m' ; Y='\033[1;33m' ; B='\033[1;34m' ; R='\033[1;31m' ; N='\033[0m'

echo -ne "${Y}[?] الصق مفتاح Render API: ${N}"
read RENDER_API_KEY

# 1. جلب الـ Owner ID
OWNER_ID=$(curl -s https://api.render.com/v1/owners \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  | jq -r '.[0].owner.id')

echo -e "${G}[✓] تم التعرف على الهوية: $OWNER_ID${N}"

# 2. إنشاء الخدمة مباشرة (Direct Docker Web Service)
echo -e "${Y}[*] جاري إنشاء السيرفر النووي لـ MASSA...${N}"

RESPONSE=$(curl -s -X POST https://api.render.com/v1/services \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "web_service",
    "name": "massa-imperial-core",
    "ownerId": "'$OWNER_ID'",
    "repo": "https://github.com/Rasan-co-sa/MASA_IMPERIAL_OS",
    "autoDeploy": "yes",
    "serviceDetails": {
      "env": "docker",
      "plan": "free",
      "region": "oregon",
      "numInstances": 1
    }
  }')

if [[ $RESPONSE == *"id"* ]]; then
    SERVICE_URL=$(echo $RESPONSE | jq -r '.serviceDetails.parentServer.url // "جاري التجهيز..."')
    echo -e "${B}=======================================${N}"
    echo -e "${G}    [✓] تم الاختراق والإنشاء بنجاح!     ${N}"
    echo -e "${G}    السيرفر الآن في مرحلة الـ Build.     ${N}"
    echo -e "${B}=======================================${N}"
else
    echo -e "${R}[!] خطأ في الرد: $RESPONSE${N}"
fi
