#!/bin/bash

# 🔹 سكربت تشغيل الباكيند وبناء APK كامل

echo "🚀 Starting Full Build for Sovereign Android..."

# 1️⃣ تثبيت الحزم مع legacy-peer-deps
echo "📦 Installing npm packages with legacy-peer-deps..."
npm install --legacy-peer-deps
if [ $? -ne 0 ]; then
    echo "❌ Error installing npm packages!"
    exit 1
fi

# 2️⃣ تشغيل الباكيند المحلي (Python)
echo "🚀 Starting local backend..."
if [ -f ./backend/main.py ]; then
    python3 ./backend/main.py &
    BACKEND_PID=$!
    echo "✅ Backend running with PID $BACKEND_PID"
else
    echo "⚠️ Backend script not found!"
fi

# 3️⃣ بناء APK باستخدام Expo (legacy) أو EAS Build
echo "📦 Building APK via Expo..."
read -p "هل تريد استخدام EAS Build؟ (y/n): " USE_EAS
if [[ "$USE_EAS" == "y" || "$USE_EAS" == "Y" ]]; then
    # EAS Build
    eas build -p android --profile production
else
    # Expo Classic Build
    npx expo prebuild
    npx expo run:android
fi

# 4️⃣ إنهاء الباكيند بعد الإنتهاء
if [ ! -z "$BACKEND_PID" ]; then
    echo "🛑 Stopping local backend..."
    kill $BACKEND_PID
fi

echo "✅ Full build process completed!"
