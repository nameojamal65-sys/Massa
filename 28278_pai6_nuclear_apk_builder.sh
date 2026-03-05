#!/bin/bash
# 👑 PAI6 Nuclear Auto-APK Builder – Lightning Mode
# 🚀 يقوم بإنشاء APK كامل مباشرة من PAI6 Root، يدير كل المكتبات والبيئة، سريع كالبرق

set -e
ROOT="$HOME/PAI6_UltimateClosure"
APK_OUTPUT="$ROOT/windows_build/PAI6.apk"
KIVY_PROJECT="$ROOT/kivy_app"
LOGFILE="$ROOT/reports/nuclear_build.log"

# إنشاء المجلدات الأساسية
mkdir -p "$ROOT/windows_build" "$ROOT/reports" "$KIVY_PROJECT/assets"

echo "⚡ Starting Nuclear APK Build..." | tee -a "$LOGFILE"

# -----------------------------
# تثبيت أي مكتبات ناقصة تلقائيًا
# -----------------------------
echo "⚡ Installing required system tools..." | tee -a "$LOGFILE"
pkg install -y python git openjdk-17 zip unzip wget curl >/dev/null 2>&1

echo "⚡ Upgrading pip and installing Python packages..." | tee -a "$LOGFILE"
pip install --upgrade pip >/dev/null 2>&1
for pkg in requests kivy buildozer numpy pandas fastapi uvicorn; do
pip install $pkg >/dev/null 2>&1 || echo "⚠️ Failed to install $pkg"
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
return Label(text="👑 PAI6 Nuclear Closure Running ⚡")

if __name__ == "__main__":
PAI6App().run()
EOL

# نسخ ملفات PAI6 الأساسية
cp -r "$ROOT/core" assets/
cp -r "$ROOT/dashboard" assets/
cp -r "$ROOT/scanner" assets/

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
# تشغيل البناء النووي
# -----------------------------
echo "⚡ Building APK (this may take a few minutes)..." | tee -a "$LOGFILE"
buildozer -v android debug >/dev/null 2>&1 || echo "⚠️ Buildozer failed, check logs"

# -----------------------------
# نقل APK النهائي
# -----------------------------
if [ -f "bin/PAI6-0.1-debug.apk" ]; then
mv bin/PAI6-0.1-debug.apk "$APK_OUTPUT"
echo "✅ Nuclear APK created at $APK_OUTPUT" | tee -a "$LOGFILE"
else
echo "⚠️ APK build failed" | tee -a "$LOGFILE"
fi

echo "⚡ Nuclear APK Build Complete – Ready to install!" | tee -a "$LOGFILE"