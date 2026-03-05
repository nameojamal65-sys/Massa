#!/bin/bash

echo "🚀 Fully Automated Sovereign APK Build for Termux"

# 1️⃣ تثبيت Node.js (إذا لم يكن مثبت)
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    pkg install nodejs-lts -y
fi

# 2️⃣ تثبيت Python (إذا لم يكن مثبت)
if ! command -v python3 &> /dev/null; then
    echo "📦 Installing Python..."
    pkg install python -y
fi

# 3️⃣ تثبيت wget و git
pkg install wget git -y

# 4️⃣ تثبيت EAS CLI إذا لم يكن موجود
if ! command -v eas &> /dev/null; then
    echo "📦 Installing EAS CLI..."
    npm install -g eas-cli
fi

# 5️⃣ تثبيت npm packages مع legacy-peer-deps
echo "📦 Installing npm packages..."
npm install --legacy-peer-deps

# 6️⃣ تحديث React و React Native
echo "⚠️ Updating React & React Native..."
npm install react@latest react-native@latest --legacy-peer-deps

# 7️⃣ إعداد الباكند المحلي إذا غير موجود
BACKEND_DIR="./backend"
if [ ! -d "$BACKEND_DIR" ]; then
    echo "📦 Creating backend..."
    mkdir -p $BACKEND_DIR
    cat <<EOL > $BACKEND_DIR/main.py
from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/api/hello")
def hello():
    return jsonify({"message": "Sovereign backend is running!"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOL
fi

# 8️⃣ تشغيل الباكند في الخلفية
echo "🖥 Starting backend..."
python3 $BACKEND_DIR/main.py &
BACKEND_PID=$!

# 9️⃣ تسجيل الدخول لـ EAS CLI تلقائيًا (تحتاج Expo حساب مسبق)
if ! eas whoami &> /dev/null; then
    echo "ℹ️ Please log in to Expo EAS CLI now"
    eas login
fi

# 🔟 بناء APK تلقائيًا
echo "📦 Building APK via EAS..."
BUILD_OUTPUT=$(eas build --platform android --profile production --non-interactive --json)

# 1️⃣1️⃣ استخراج رابط التحميل
APK_URL=$(echo $BUILD_OUTPUT | python3 -c "import sys, json; print(json.load(sys.stdin)['artifacts'][0]['uri'])")

# 1️⃣2️⃣ تنزيل APK تلقائيًا
if [ ! -z "$APK_URL" ]; then
    echo "⬇️ Downloading APK..."
    wget -O sovereign_app.apk "$APK_URL"
    echo "✅ APK downloaded as sovereign_app.apk"
else
    echo "❌ Failed to get APK URL. Check EAS build logs."
fi

# 1️⃣3️⃣ إيقاف الباكند بعد البناء
kill $BACKEND_PID
echo "🖥 Backend stopped."
echo "✅ Fully Automated APK Build Complete!"
echo "🌐 Backend endpoint: http://localhost:5000/api/hello"
