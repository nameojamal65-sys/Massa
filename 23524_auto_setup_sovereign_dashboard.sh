#!/bin/bash
# --- Fully Automatic Sovereign Dashboard Setup & Launch ---

DASHBOARD_DIR=~/sovereign_dashboard

# حذف أي مجلد قديم
if [ -d "$DASHBOARD_DIR" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_DIR"
fi

# إنشاء مشروع React + Vite جديد بدون أي أسئلة
echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@latest "$DASHBOARD_DIR" -- --template react --force

# الانتقال للمجلد وتثبيت الاعتمادات
cd "$DASHBOARD_DIR" || exit
echo "🔹 Installing dependencies..."
npm install
npm install axios

# تشغيل المشروع في الخلفية وفتح المتصفح
echo "🔹 Starting the dashboard..."
npm run dev &

# محاولة فتح الرابط تلقائياً (يدعم Termux و Linux GUI)
URL="http://127.0.0.1:5173"
if command -v xdg-open &> /dev/null; then
    xdg-open "$URL"
elif command -v am start &> /dev/null; then
    am start -a android.intent.action.VIEW -d "$URL"
fi

echo "✅ Dashboard should now be running at $URL"
