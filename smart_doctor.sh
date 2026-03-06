#!/bin/bash
echo "[*] الفحص النهائي لمشروع MASA..."
if [ -f "src/package.json" ]; then
    echo "[✓] ملف package.json موجود في src."
else
    echo "[!] خطأ: package.json مفقود!"
fi

if [ -f "render.yaml" ]; then
    echo "[✓] ملف render.yaml موجود وجاهز للتلقين."
else
    echo "[!] تحذير: لا يوجد render.yaml، ستحتاج لضبط الإعدادات يدوياً في رندر."
fi
echo "[*] جاهز للرفع!"
