#!/bin/bash
echo "📦 تحديث Termux..."
pkg update -y && pkg upgrade -y

echo "🔧 تثبيت الأدوات الأساسية..."
for pkgname in python git wget curl nano unzip zip openjdk-17 clang make cmake nodejs build-essential autoconf automake libtool pkg-config zlib-dev libffi-dev; do
    if ! command -v $pkgname >/dev/null 2>&1; then
        pkg install -y $pkgname
    fi
done

echo "📦 تثبيت مكتبات Python..."
pip install --upgrade pip setuptools wheel
for lib in kivy buildozer pyjnius pyinstaller; do
    pip show $lib >/dev/null 2>&1 || pip install $lib
done

echo "📁 إنشاء مشروع APK..."
mkdir -p ~/LegendaryAPK/project
cd ~/LegendaryAPK/project

echo "🛠 إنشاء ملف Kivy رئيسي..."
cat <<'PY' > main.py
from kivy.app import App
from kivy.uix.label import Label

class MyApp(App):
    def build(self):
        return Label(text="Hello Legendary APK Ultimate Fast!")

if __name__ == "__main__":
    MyApp().run()
PY

echo "🚀 إعداد Buildozer إذا لم يكن موجود..."
[ ! -f buildozer.spec ] && buildozer init

echo "⚡ بدء بناء APK..."
buildozer android debug deploy run

echo "🟢 APK جاهز!"
echo "موقعه: ~/LegendaryAPK/project/bin/"
