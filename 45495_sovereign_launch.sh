#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Sovereign Smart Launcher Starting..."

PROJECT_DIR="$HOME/sovereign_dashboard"
BACKEND_FILE="$HOME/sovereign_core_full.py"

# تثبيت Node إذا غير موجود
if ! command -v node &> /dev/null
then
    echo "📦 Installing NodeJS..."
    pkg install nodejs -y
fi

# إنشاء مشروع Vite إذا غير موجود
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📁 Creating Vite React Project..."
    npm create vite@latest sovereign_dashboard -- --template react
    cd $PROJECT_DIR
    npm install
else
    cd $PROJECT_DIR
fi

# تثبيت axios إذا غير مثبت
if ! grep -q "axios" package.json; then
    echo "📦 Installing axios..."
    npm install axios
fi

# إنشاء ملف env إذا غير موجود
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file..."
    echo "VITE_API_URL=http://127.0.0.1:5000" > .env
fi

# تشغيل Backend إذا موجود
if [ -f "$BACKEND_FILE" ]; then
    echo "🧠 Starting Backend..."
    export OPENAI_API_KEY=$OPENAI_API_KEY
    nohup python3 $BACKEND_FILE > backend.log 2>&1 &
else
    echo "⚠️ Backend file not found at $BACKEND_FILE"
fi

# تشغيل Frontend
echo "🌐 Starting Frontend..."
npm run dev
