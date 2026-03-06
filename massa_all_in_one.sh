#!/bin/bash
# Massa All-in-One Engine v6.0

# 1. تعريف الهوية
KEY=$(cat .render_key 2>/dev/null)
[ -z "$KEY" ] && { echo "[!] خطأ: ملف .render_key مفقود."; exit 1; }

# 2. إنشاء خريطة البناء (render.yaml)
echo "[*] جاري إنشاء خريطة البناء (render.yaml)..."
cat <<EOF > render.yaml
services:
  - type: web
    name: massa-bot-pro
    runtime: node
    buildCommand: npm install
    startCommand: node src/index.js
    envVars:
      - key: NODE_VERSION
        value: "18"
      - key: NPM_CONFIG_PRODUCTION
        value: "false"
EOF

# 3. قائمة العمليات التفاعلية
echo "======================================"
echo "      MASA ALL-IN-ONE ENGINE"
echo "======================================"
echo "1) دفع الإعدادات للـ GitHub (Git Push)"
echo "2) فرض إعادة البناء (Force Deploy)"
echo "3) فحص حالة الخدمة"
echo "======================================"
read -p "[?] اختر العملية (1-3): " CHOICE

case $CHOICE in
    1)
        git add render.yaml
        git commit -m "Add render.yaml for auto-deploy"
        git push
        echo "[✓] تم دفع الإعدادات للـ GitHub."
        ;;
    2)
        read -p "أدخل Service ID الخاص بك: " SID
        echo "[*] جاري فرض البناء..."
        curl -X POST "https://api.render.com/v1/services/$SID/deploys" \
             -H "Authorization: Bearer $KEY"
        echo "[✓] تم إرسال أمر البناء."
        ;;
    3)
        read -p "أدخل Service ID الخاص بك: " SID
        curl -s -H "Authorization: Bearer $KEY" "https://api.render.com/v1/services/$SID" | jq .
        ;;
    *) echo "[!] اختيار غير صحيح." ;;
esac
