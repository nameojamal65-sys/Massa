#!/data/data/com.termux/files/usr/bin/bash
echo "📦 تحديث Termux وتثبيت الأدوات الأساسية..."
pkg update -y && pkg upgrade -y
pkg install -y git curl wget nano net-tools vim build-essential zip unzip python nodejs openjdk-17 imagemagick leptonica

echo "📦 تثبيت Python pip وحزمها..."
pip install --upgrade pip setuptools wheel
pip install fastapi uvicorn psutil aiosqlite websockets kivy pyjnius

echo "📦 تثبيت NodeJS وحزم npm..."
npm install -g npm
npm install -g npx

echo "📦 إنشاء مجلدات المشروع..."
mkdir -p ~/Legendary_Dashboard/backend
mkdir -p ~/Legendary_Dashboard/frontend

echo "📁 إنشاء مشروع Backend فارغ..."
cd ~/Legendary_Dashboard/backend
echo "from fastapi import FastAPI\napp = FastAPI()\n\n@app.get('/')\ndef read_root():\n    return {'status': 'Backend Ready'}" > main.py

echo "📁 إنشاء مشروع Frontend فارغ..."
cd ~/Legendary_Dashboard/frontend
npx create-react-app legendary_frontend

echo "🛑 إيقاف أي نسخ قديمة..."
pkill -f uvicorn || true

echo "🚀 تشغيل Backend..."
cd ~/Legendary_Dashboard/backend
nohup uvicorn main:app --host 0.0.0.0 --port 9000 &

echo "🌐 تشغيل Frontend..."
cd ~/Legendary_Dashboard/frontend/legendary_frontend
nohup npm start &

echo "🔥 Legendary APK FullStack Setup Ready!"
echo "Backend: http://127.0.0.1:9000"
echo "Frontend: http://127.0.0.1:3000"
