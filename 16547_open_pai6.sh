#!/data/data/com.termux/files/usr/bin/bash

# ------------------------------------------
# فتح منظومة PAI6 Master بالكامل
# ------------------------------------------

# مسارات مهمة
HOME_DIR="$HOME"
PAI6_DIR="$HOME_DIR/PAI6"
OUTPUT="$PAI6_DIR/realized"
LOG="$PAI6_DIR/logs"
DASHBOARD_URL="http://127.0.0.1:8080"

# 1️⃣ تشغيل المنظومة إذا لم تعمل
echo "🚀 تشغيل PAI6 Master..."
if pgrep -f "PAI6_master.sh" > /dev/null; then
    echo "✅ المنظومة تعمل بالفعل"
else
    echo "⏳ جاري تشغيل PAI6 Master..."
    bash "$PAI6_DIR/PAI6_master.sh" &
    sleep 5
fi

# 2️⃣ فتح لوحة التحكم في المتصفح
echo "🌐 فتح لوحة التحكم في المتصفح..."
termux-open-url "$DASHBOARD_URL"

# 3️⃣ فتح مجلد الملفات المعالجة
echo "📂 فتح مجلد الملفات المعالجة..."
ls -lh "$OUTPUT"

# 4️⃣ عرض التقرير النهائي
echo "📄 عرض التقرير النهائي..."
nano "$LOG/final_report.txt"

# 5️⃣ عرض أرشيفات النظام
echo "🗂️ أرشيفات النظام المضغوطة:"
ls -lh "$PAI6_DIR" | grep ".zip"

echo "✅ كل شيء جاهز. يمكنك تصفح الملفات والتقارير الآن."
