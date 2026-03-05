#!/bin/bash

echo "🧹 Final Root Cleanup"

# نقل أي agent متبقي
mv ai_server_agent.py agents/ 2>/dev/null

# إنشاء مجلد app_entry
mkdir -p app_entry

# نقل ملفات التشغيل الرئيسية
mv Legendary_Dashboard.py app_entry/ 2>/dev/null
mv legendary_dashboard.py app_entry/ 2>/dev/null

# حذف السكربت المؤقت
rm -f fix_structure_inside_project.sh

echo "--------------------------------"
echo "📊 الشكل النهائي:"
ls -lah
echo "--------------------------------"
echo "🏆 Project is now Architecturally Clean."
