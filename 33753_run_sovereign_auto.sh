#!/bin/bash
# ===============================
# 🚀 Auto-launch Sovereign Full Package (Termux)
# ===============================

# مسار الأرشيف
ARCHIVE="$HOME/sovereign_final_server.tar.gz"
TARGET_DIR="$HOME/sovereign_final"

# تحقق من وجود الأرشيف
if [ ! -f "$ARCHIVE" ]; then
    echo "❌ خطأ: الأرشيف $ARCHIVE غير موجود!"
    exit 1
fi

# فك الضغط
echo "📦 فك الضغط..."
mkdir -p "$TARGET_DIR"
tar -xzf "$ARCHIVE" -C "$TARGET_DIR"

# ادخل المجلد النهائي
cd "$TARGET_DIR" || { echo "❌ خطأ: لم أتمكن من الدخول للمجلد."; exit 1; }

# إعداد بورت فاضي
PORT=8080
while lsof -i:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
echo "🔹 سيتم تشغيل التطبيق على المنفذ $PORT..."

# تثبيت المكتبات المطلوبة تلقائيًا
if [ -f "requirements.txt" ]; then
    echo "🔧 تثبيت المكتبات المطلوبة..."
    pip install --no-cache-dir -r requirements.txt
fi

# تشغيل التطبيق
echo "🚀 تشغيل Sovereign Core..."
nohup python3 -m uvicorn core.main:app --host 127.0.0.1 --port $PORT > sovereign.log 2>&1 &

echo "✅ التطبيق شغال على: http://127.0.0.1:$PORT"
echo "💾 سجلات التشغيل محفوظة في sovereign.log"
