#!/bin/bash

echo "📦 تحديث Termux وتثبيت الأدوات الأساسية..."
pkg update -y && pkg upgrade -y

for pkgname in python git wget curl nano unzip zip clang make cmake nodejs build-essential autoconf automake libtool; do
    if ! command -v $pkgname >/dev/null 2>&1; then
        pkg install -y $pkgname
    fi
done

echo "📦 تثبيت مكتبات Python الضرورية..."
pip install --upgrade pip setuptools wheel
for lib in kivy buildozer pyjnius pyinstaller; do
    pip show $lib >/dev/null 2>&1 || pip install $lib
done

echo "📁 إنشاء مشروع APK..."
mkdir -p ~/LegendaryAPK/project
cd ~/LegendaryAPK/project

# ملف Kivy رئيسي
cat <<'PY' > main.py
from kivy.app import App
from kivy.uix.label import Label

class MyApp(App):
    def build(self):
        return Label(text="Hello Legendary APK Ultimate Fast!")

if __name__ == "__main__":
    MyApp().run()
PY

# إعداد Buildozer إذا لم يكن موجود
[ ! -f buildozer.spec ] && buildozer init

echo "⚡ بناء APK..."
buildozer android debug

APK_FILE=$(ls bin/*.apk 2>/dev/null | head -n 1)

if [ -f "$APK_FILE" ]; then
    echo "📦 تثبيت APK..."
    pm install -r "$APK_FILE"
    
    PACKAGE_NAME=$(grep "^package" buildozer.spec | cut -d '=' -f2 | tr -d ' ')
    echo "🚀 تشغيل التطبيق..."
    am start -n "$PACKAGE_NAME/.MainActivity"
    echo "🟢 تم تشغيل التطبيق بنجاح!"
else
    echo "❌ لم يتم العثور على أي APK. تحقق من Buildozer."
fi
