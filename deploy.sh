#!/bin/bash
source deploy_config.sh
echo "[*] جاري الرفع إلى GitHub..."
git add .
git commit -m "تحديث تلقائي من Termux"
git push -u origin main --force
echo "[*] جاري إرسال أمر البناء إلى Render..."
curl -X POST https://api.render.com/v1/services/$SERVICE_ID/deploys \
  -H "Authorization: Bearer $API_KEY"
echo "[✓] تمت العملية بنجاح!"
