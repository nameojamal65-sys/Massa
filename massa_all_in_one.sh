#!/bin/bash

# دالة التأكد من التوكن
ensure_token() {
    if [ ! -f .github_token ] || [ ! -s .github_token ]; then
        echo "[!] لم يتم العثور على التوكن. يرجى إدخال GitHub Personal Access Token:"
        read -s token
        echo "$token" > .github_token
        echo "[✓] تم حفظ التوكن بنجاح."
    fi
}

check_deploy_status() {
    ensure_token
    echo "[*] جاري فحص حالة البناء على GitHub..."
    TOKEN=$(cat .github_token)
    curl -s -H "Authorization: token $TOKEN" \
         https://api.github.com/repos/nameojamal65-sys/Massa/actions/runs \
         | jq -r '.workflow_runs[0] | "الحالة: \(.status) | النتيجة: \(.conclusion)"'
}

echo "================================"
echo "      MASA MASTER ENGINE v2.1"
echo "================================"
echo "1) دفع التحديثات (Push & Deploy)"
echo "2) مراقبة الحالة (GitHub Monitor)"
echo "3) خروج"
echo "================================"
read -p "[?] اختر العملية: " choice

case $choice in
    1)
        git add .
        git commit -m "Auto-Deploy: $(date)"
        git push
        echo "[✓] تم الرفع! البناء جارٍ الآن في الخلفية."
        ;;
    2)
        check_deploy_status
        ;;
    3)
        exit 0
        ;;
    *)
        echo "[!] اختيار غير صحيح."
        ;;
esac
