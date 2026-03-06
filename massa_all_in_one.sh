#!/bin/bash

deploy_direct() {
    if [ ! -f .render_key ]; then
        echo "[!] خطأ: ملف .render_key مفقود."
        return
    fi
    KEY=$(cat .render_key)
    echo "[*] جاري تنفيذ النشر المباشر إلى Render..."
    RESPONSE=$(curl -s -X POST https://api.render.com/v1/services/srv-d4v3hvmr433s73du23t0/deploys \
         -H "Authorization: Bearer $KEY")
    echo "[✓] استجابة رندر: $RESPONSE"
}

echo "================================"
echo "      MASA MASTER ENGINE v3.1"
echo "================================"
echo "1) رفع الكود لـ GitHub (Push)"
echo "2) النشر المباشر لـ Render (Deploy)"
echo "3) خروج"
echo "================================"
read -p "[?] اختر العملية: " choice

case $choice in
    1)
        git add .
        git commit -m "Masa-Update: $(date)"
        git push
        ;;
    2)
        deploy_direct
        ;;
    3)
        exit 0
        ;;
    *)
        echo "[!] خيار غير صحيح."
        ;;
esac
