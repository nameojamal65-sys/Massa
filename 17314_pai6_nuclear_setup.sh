#!/data/data/com.termux/files/usr/bin/bash
clear
echo "👑 PAI6 — NUCLEAR PACKAGE SETUP"
echo "==============================="
sleep 1

# 1️⃣ Paths
NUCLEAR_ARCHIVE=~/pai6_export/pai6_FULL_NUCLEAR_BUILD.tar.gz
BUILD_DIR=~/pai6_final_build
ASSETS_DIR=~/pai6_assets

# 2️⃣ إنشاء مجلدات البناء والموارد
mkdir -p "$BUILD_DIR"
mkdir -p "$ASSETS_DIR"

# 3️⃣ تعليمات لوضع الملفات المطلوبة
echo "⚠️ ضع الملفات التالية داخل $ASSETS_DIR قبل التشغيل:"
echo "- intro.mp4 (فيديو المقدمة)"
echo "- logo.png (شعار + توقيع)"
echo "- license_manager.py (QR License)"

# 4️⃣ نسخ الموارد (تتحقق فقط إذا كانت موجودة)
for f in intro.mp4 logo.png license_manager.py; do
  if [ -f "$ASSETS_DIR/$f" ]; then
    cp "$ASSETS_DIR/$f" "$BUILD_DIR/"
    echo "✅ $f copied"
  else
    echo "❌ $f NOT FOUND! ضع الملف في $ASSETS_DIR"
  fi
done

# 5️⃣ استخراج الحزمة النووية
echo "📦 Extracting nuclear package..."
tar -xzvf "$NUCLEAR_ARCHIVE" -C "$BUILD_DIR"

# 6️⃣ إنشاء buildozer.spec
echo "⚙️ Generating buildozer.spec..."
cat <<EOF > "$BUILD_DIR/buildozer.spec"
[app]
title = PAI6 — Sovereign Node
package.name = pai6.sovereign.node
package.domain = pai6.sovereign
source.dir = .
source.include_exts = py,png,jpg,kv,json,txt,mp4
version = 1.0
requirements = python3,kivy,cython,flask,fastapi,requests,pillow,psutil,qrcode,opencv-python
orientation = portrait
fullscreen = 1
android.permissions = INTERNET,READ_EXTERNAL_STORAGE,WRITE_EXTERNAL_STORAGE

[buildozer]
log_level = 2
warn_on_root = 0
EOF

# 7️⃣ إنشاء سكربت البناء التلقائي
echo "⚙️ Generating build_auto.sh..."
cat <<'EOF' > "$BUILD_DIR/build_auto.sh"
#!/usr/bin/env bash
clear
echo "🚀 PAI6 Final APK Builder"
echo "========================="
pkg update -y
pkg install -y python git zip unzip openjdk-17-jdk adb
pip install --upgrade buildozer cython
pip install -r requirements.txt
buildozer android clean
buildozer android debug
echo "=============================="
echo "✅ FINAL APK GENERATED SUCCESSFULLY"
echo "📦 Location: bin/*.apk"
echo "=============================="
EOF

chmod +x "$BUILD_DIR/build_auto.sh"

# 8️⃣ نسخ requirements.txt إذا لم يكن موجود
if [ ! -f "$BUILD_DIR/requirements.txt" ]; then
  echo "⚙️ Creating default requirements.txt..."
  cat <<EOF > "$BUILD_DIR/requirements.txt"
kivy
buildozer
cython
cryptography
qrcode
opencv-python
flask
fastapi
uvicorn
jinja2
psutil
requests
pillow
EOF
fi

echo "🎯 PAI6 nuclear build environment ready in $BUILD_DIR"
echo "➡️ Run ./build_auto.sh inside $BUILD_DIR to generate final APK"
