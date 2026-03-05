#!/data/data/com.termux/files/usr/bin/bash
# legendary_apk_builder_ready.sh
# سكربت تجهيز مشروع Android جاهز للبناء في Android Studio

PROJECT_DIR="$HOME/Legendary_v6_APK"
FRONTEND_BUILD="$HOME/Legendary_Dashboard/v6/frontend/build"
BACKEND_DIR="$HOME/Legendary_Dashboard/v6/backend"

echo "📦 بدء إعداد مشروع Android جديد..."

# حذف المشروع القديم إذا موجود
if [ -d "$PROJECT_DIR" ]; then
    echo "🗑️ حذف المشروع القديم..."
    rm -rf "$PROJECT_DIR"
fi

# إنشاء مجلد المشروع
mkdir -p "$PROJECT_DIR"

# نسخ Frontend React build
if [ -d "$FRONTEND_BUILD" ]; then
    echo "🌐 نسخ ملفات frontend build..."
    mkdir -p "$PROJECT_DIR/frontend"
    cp -r "$FRONTEND_BUILD"/* "$PROJECT_DIR/frontend/"
else
    echo "⚠️ مجلد Frontend build غير موجود! تأكد من تنفيذ 'npm run build' في frontend أولاً."
fi

# نسخ Backend Python
if [ -d "$BACKEND_DIR" ]; then
    echo "🧠 نسخ ملفات Backend Python..."
    mkdir -p "$PROJECT_DIR/backend"
    cp -r "$BACKEND_DIR"/* "$PROJECT_DIR/backend/"
else
    echo "⚠️ مجلد Backend غير موجود! تأكد من وجود سكربتات Python."
fi

# إنشاء ملفات أساسية Android Studio
echo "⚙️ تجهيز ملفات Android Studio..."
mkdir -p "$PROJECT_DIR/app/src/main/assets"
mkdir -p "$PROJECT_DIR/app/src/main/python"

# نسخ Frontend + Backend إلى مجلدات Android Studio
cp -r "$PROJECT_DIR/frontend"/* "$PROJECT_DIR/app/src/main/assets/"
cp -r "$PROJECT_DIR/backend"/* "$PROJECT_DIR/app/src/main/python/"

# تعليمات للمستخدم
echo "✅ مشروع Android جاهز!"
echo "📂 المسار: $PROJECT_DIR"
echo "🔥 بعد فتح المشروع في Android Studio:"
echo "   1. Build → Build APK(s) → Build APK(s)"
echo "   2. ستجد APK النهائي في $PROJECT_DIR/app/build/outputs/apk/"
