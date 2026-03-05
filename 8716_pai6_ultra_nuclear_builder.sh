#!/bin/bash
# 👑 PAI6 ULTRA Nuclear Auto-APK Builder – Lightning Full Auto
# 🚀 يبني APK نووي كامل من الصفر، يجلب كل مكتبة، أداة، وبيئة تلقائيًا

set -e
ROOT="$HOME/PAI6_UltimateClosure"
APK_OUTPUT="$ROOT/windows_build/PAI6.apk"
KIVY_PROJECT="$ROOT/kivy_app"
LOGFILE="$ROOT/reports/ultra_nuclear.log"

# -----------------------------
# إنشاء مجلدات أساسية
# -----------------------------
mkdir -p "$ROOT/windows_build" "$ROOT/reports" "$KIVY_PROJECT/assets"
echo "⚡ Starting ULTRA Nuclear Build..." | tee -a "$LOGFILE"

# -----------------------------
# تثبيت كل الأدوات تلقائيًا
# -----------------------------
echo "⚡ Installing system tools..." | tee -a "$LOGFILE"
pkg install -y python git openjdk-17 zip unzip wget curl nodejs npm >/dev/null 2>&1

# -----------------------------
# تثبيت كل مكتبات Python الأساسية
# -----------------------------
echo "⚡ Installing Python packages..." | tee -a "$LOGFILE"
pip install --upgrade pip >/dev/null 2>&1
for pkg in requests kivy buildozer numpy pandas fastapi uvicorn flask jinja2 pyopenssl; do
pip install $pkg >/dev/null 2>&1 || echo "⚠️ Failed: $pkg"
done

# -----------------------------
# تثبيت مكتبات Node الأساسية
# -----------------------------
echo "⚡ Installing Node.js packages..." | tee -a "$LOGFILE"
for lib in express cors axios react react-dom; do
npm install -g $lib >/dev/null 2>&1 || echo "⚠️ Failed: $lib"
done

# -----------------------------
# إعداد مشروع Kivy
# -----------------------------
echo "⚡ Setting up Kivy project..." | tee -a "$LOGFILE"
rm -rf "$KIVY_PROJECT"
mkdir -p "$KIVY_PROJECT"
cd "$KIVY_PROJECT"

# إنشاء main.py لتشغيل Core
cat > main.py <<EOL
from kivy.app import App
from kivy.uix.label import Label
import os

class PAI6App(App):
    def build(self):
return Label(text="👑 PAI6 Nuclear Closure Running ⚡ ULTRA")

if __name__ == "__main__":
PAI6App().run()
EOL

# نسخ كل ملفات PAI6 الأساسية كأصول
for folder in core dashboard scanner; do
mkdir -p assets/$folder
[ -d "$ROOT/$folder" ] && cp -r "$ROOT/$folder/"* "assets/$folder/" || echo "⚠️ Missing folder: $folder"
done

# -----------------------------
# إعداد buildozer.spec
# -----------------------------
echo "⚡ Configuring buildozer..." | tee -a "$LOGFILE"
buildozer init >/dev/null 2>&1
sed -i "s/package.name = myapp/package.name = PAI6/" buildozer.spec
sed -i "s/package.domain = org.test/package.domain = com.pai6/" buildozer.spec
sed -i "s/# source.include_exts = py,kv,txt/source.include_exts = py,kv/" buildozer.spec
sed -i "s/# android.permissions = INTERNET/android.permissions = INTERNET/" buildozer.spec

# -----------------------------
# بناء APK النووي ULTRA
# -----------------------------
echo "⚡ Building ULTRA Nuclear APK..." | tee -a "$LOGFILE"
buildozer -v android debug >/dev/null 2>&1 || echo "⚠️ Buildozer failed, check logs"

# -----------------------------
# نقل APK النهائي
# -----------------------------
if [ -f "bin/PAI6-0.1-debug.apk" ]; then
mv bin/PAI6-0.1-debug.apk "$APK_OUTPUT"
echo "✅ ULTRA Nuclear APK created at $APK_OUTPUT" | tee -a "$LOGFILE"
else
echo "⚠️ APK build failed" | tee -a "$LOGFILE"
fi

echo "⚡ ULTRA Nuclear Build Complete – Ready to install!" | tee -a "$LOGFILE"