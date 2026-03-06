#!/bin/bash
# سكربت الإنشاء العنيد - Massa Smart Deploy

clear
echo "--- MASA SMART DEPLOY: البحث عن الـ OwnerID ---"

# 1. إدخال المفتاح
read -p "أدخل Render API Key: " API_KEY

# 2. البحث العنيد عن الـ OwnerID
echo "[*] جاري البحث عن الهوية (OwnerID) المرتبطة بهذا المفتاح..."

# محاولة جلب المستخدم أو الفرق المرتبطة بالمفتاح
OWNER_ID=$(curl -s -H "Authorization: Bearer $API_KEY" "https://api.render.com/v1/services" | grep -o '"ownerId":"[^"]*"' | head -1 | cut -d'"' -f4)

# إذا فشل، نحاول جلب معلومات الحساب مباشرة
if [ -z "$OWNER_ID" ]; then
    OWNER_ID=$(curl -s -H "Authorization: Bearer $API_KEY" "https://api.render.com/v1/user" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# التحقق النهائي
if [ -z "$OWNER_ID" ]; then
    echo "[!] فشل ذريع: لا يمكن العثور على OwnerID. تأكد أن المفتاح يمتلك صلاحيات كاملة."
    exit 1
else
    echo "[✓] تم العثور على الهوية الذكية: $OWNER_ID"
fi

# 3. إكمال البيانات
read -p "اسم الخدمة: " NAME
read -p "رابط GitHub: " REPO

echo "[*] جاري تنفيذ أمر الإنشاء..."

# 4. تنفيذ الطلب
RESPONSE=$(curl -s -X POST "https://api.render.com/v1/services" \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "type": "web",
       "name": "'"$NAME"'",
       "ownerId": "'"$OWNER_ID"'",
       "repo": "'"$REPO"'",
       "serviceDetails": {
         "runtime": "node",
         "buildCommand": "npm install",
         "startCommand": "node src/index.js"
       }
     }')

# 5. عرض النتيجة
echo "[*] رد رندر النهائي:"
echo $RESPONSE | jq .

SERVICE_ID=$(echo $RESPONSE | grep -o '"id":"srv-[^"]*"' | cut -d'"' -f4)
if [ ! -z "$SERVICE_ID" ]; then
    echo $SERVICE_ID > .service_id
    echo "[✓] تم الإنشاء بنجاح! الـ ID هو: $SERVICE_ID"
fi
