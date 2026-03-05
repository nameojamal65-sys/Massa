#!/bin/bash
# ================================
# سكربت تحزيم وتشغيل Sovereign الكامل
# ================================

# مجلد التطبيق الأصلي
APP_DIR="$HOME/sovereign_production"

# مجلد الحزمة النهائي
PACKAGE_DIR="$HOME/sovereign_package"

# ملف الدخول الرئيسي
APP_ENTRY="core.main:app"

# إنشاء مجلد الحزمة ونسخ كل شيء
echo "📦 إنشاء حزمة Sovereign..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"
cp -r "$APP_DIR"/* "$PACKAGE_DIR"/

# البحث عن بورت فاضي بدءًا من 8080
PORT=8080
while lsof -i:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done

echo "🔹 تشغيل التطبيق على المنفذ $PORT..."

# الانتقال لمجلد الحزمة
cd "$PACKAGE_DIR" || { echo "❌ مجلد الحزمة غير موجود!"; exit 1; }

# تثبيت التبعيات تلقائيًا (مع تجاوز المشاكل السابقة)
if [ -f "requirements.txt" ]; then
    echo "🔧 تثبيت التبعيات..."
    pip install --no-cache-dir -r requirements.txt || echo "⚠️ بعض المكتبات قد تحتاج تعديل نسخة"
fi

# تشغيل التطبيق على البورت الفاضي
python3 -m uvicorn "$APP_ENTRY" --host 127.0.0.1 --port $PORT --reload

echo "🚀 التطبيق شغال على: http://127.0.0.1:$PORT"
