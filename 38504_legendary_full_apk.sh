#!/data/data/com.termux/files/usr/bin/bash
echo "📦 تحديث Termux وتثبيت الأدوات الأساسية..."
pkg update -y && pkg upgrade -y
pkg install -y git curl wget nano net-tools vim build-essential zip unzip python nodejs openjdk-17 imagemagick leptonica git-lfs

echo "📦 تثبيت Python pip وحزمها..."
pip install --upgrade pip setuptools wheel
pip install fastapi uvicorn psutil aiosqlite websockets kivy pyjnius

echo "📦 تثبيت NodeJS وحزم npm..."
npm install -g npm
npm install -g npx

echo "📦 تنزيل Android SDK Command Line Tools..."
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O cmdline-tools.zip
unzip cmdline-tools.zip
rm cmdline-tools.zip

echo "📦 إعداد Android SDK..."
export ANDROID_SDK_ROOT=$HOME/android-sdk
export PATH=$ANDROID_SDK_ROOT/cmdline-tools/bin:$PATH
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2" "ndk;25.2.9519653"

echo "📦 تثبيت Gradle..."
pkg install gradle -y

echo "📁 إنشاء مجلدات المشروع..."
mkdir -p ~/Legendary_Dashboard/backend
mkdir -p ~/Legendary_Dashboard/frontend
mkdir -p ~/Legendary_Dashboard/android_app

echo "📁 إنشاء مشروع Backend فارغ..."
cd ~/Legendary_Dashboard/backend
echo "from fastapi import FastAPI\napp = FastAPI()\n\n@app.get('/')\ndef read_root():\n    return {'status': 'Backend Ready'}" > main.py

echo "📁 إنشاء مشروع Frontend فارغ..."
cd ~/Legendary_Dashboard/frontend
npx create-react-app legendary_frontend

echo "📁 إعداد مشروع Android Kivy فارغ..."
cd ~/Legendary_Dashboard/android_app
mkdir -p my_kivy_app
cd my_kivy_app
echo "from kivy.app import App\nfrom kivy.uix.label import Label\n\nclass MyApp(App):\n    def build(self):\n        return Label(text='Hello Legendary APK')\n\nif __name__ == '__main__':\n    MyApp().run()" > main.py

echo "🛑 إيقاف أي نسخ قديمة..."
pkill -f uvicorn || true

echo "🚀 تشغيل Backend..."
cd ~/Legendary_Dashboard/backend
nohup uvicorn main:app --host 0.0.0.0 --port 9000 &

echo "🌐 تشغيل Frontend..."
cd ~/Legendary_Dashboard/frontend/legendary_frontend
nohup npm start &

echo "🔥 Legendary APK FullStack & Android Build Ready!"
echo "Backend: http://127.0.0.1:9000"
echo "Frontend: http://127.0.0.1:3000"
echo "Android SDK Root: $HOME/android-sdk"
