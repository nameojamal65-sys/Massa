#!/bin/bash
# full_auto_build_all.sh
# سكربت أوتوماتيكي كامل لبناء APK و IPA لـ Sovereign Android/iOS

echo "🚀 Starting Full Automated Build All..."

# --- التحقق من Node.js ---
NODE_VERSION=$(node -v)
echo "🖥 Node.js version: $NODE_VERSION"
if [[ "$NODE_VERSION" != v18.* ]]; then
    echo "⚠️ Warning: Recommended Node.js version is 18.17.1"
fi

# --- تثبيت الحزم المطلوبة ---
echo "📦 Installing npm packages..."
npm install --legacy-peer-deps

# --- تحديث React و React Native ---
echo "⚠️ Updating React & React Native..."
npm update

# --- تشغيل backend إذا موجود ---
BACKEND_DIR="./backend"
if [ -f "$BACKEND_DIR/start_backend.sh" ]; then
    echo "🖥 Starting backend..."
    "$BACKEND_DIR/start_backend.sh" &
    BACKEND_PID=$!
else
    echo "⚠️ Backend script not found! Skipping backend."
fi

# --- بناء Android APK ---
echo "📦 Building Android APK via EAS..."
eas build --platform android --non-interactive

# --- بناء iOS IPA (إذا متاح) ---
echo "📦 Building iOS IPA via EAS..."
eas build --platform ios --non-interactive || echo "⚠️ iOS build skipped or failed"

# --- إيقاف backend إذا كان شغّال ---
if [ ! -z "$BACKEND_PID" ]; then
    echo "🖥 Stopping backend..."
    kill $BACKEND_PID
fi

echo "✅ Full Automated Build Complete!"
