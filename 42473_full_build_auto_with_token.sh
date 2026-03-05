#!/bin/bash
# سكربت أوتوماتيكي لبناء APK مع تسجيل دخول Expo تلقائيًا

# ===== إعداد متغير البيئة لـ Expo =====
# ضع توكن حسابك هنا:
EXPO_TOKEN="ضع_توكن_حسابك_هنا"
export EXPO_TOKEN

echo "🚀 Starting Automated Build for Sovereign with Expo Token..."
echo "🖥 Detected OS: $(uname -s)"
echo "⚠️ Node.js version: $(node -v)"

# ===== تثبيت التبعيات =====
echo "📦 Installing npm packages with legacy-peer-deps..."
npm install --legacy-peer-deps

# ===== تحديث React و React Native =====
echo "⚠️ Updating React & React Native..."
npm install react@latest react-native@latest --legacy-peer-deps

# ===== تثبيت EAS CLI إذا غير موجود =====
if ! command -v eas &> /dev/null
then
    echo "⚠️ EAS CLI not found. Installing..."
    npm install -g eas-cli
fi

# ===== تشغيل الباك اند =====
if [ -f ./backend_start.sh ]; then
    echo "🚀 Starting backend..."
    ./backend_start.sh &
else
    echo "⚠️ Backend script not found! Skipping backend..."
fi

# ===== بناء APK =====
echo "📦 Building Android APK via EAS..."
eas build --platform android --non-interactive

echo "✅ Build process completed!"
