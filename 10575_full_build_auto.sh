#!/bin/bash
# full_build_auto.sh - Automated Build for Android APK & iOS IPA

set -e

PROJECT_DIR=$(pwd)
BACKEND_SCRIPT="$PROJECT_DIR/backend/main.py"
DIST_DIR="$PROJECT_DIR/dist"

echo "🚀 Starting Automated Build for Sovereign..."

# Detect OS
OS_TYPE=$(uname)
echo "🖥 Detected OS: $OS_TYPE"

# 1️⃣ Node.js check
NODE_VERSION=$(node -v | tr -d 'v')
RECOMMENDED_NODE="18.17.1"
if [ "$NODE_VERSION" != "$RECOMMENDED_NODE" ]; then
    echo "⚠️ Node.js version $NODE_VERSION found, recommended is $RECOMMENDED_NODE."
fi

# 2️⃣ Install npm packages
echo "📦 Installing npm packages..."
npm install --legacy-peer-deps

# 3️⃣ Ensure React & React Native versions
REACT_VERSION=$(npm list react | grep react@ | awk -F@ '{print $2}')
RN_VERSION=$(npm list react-native | grep react-native@ | awk -F@ '{print $2}')
RECOMMENDED_REACT="19.2.4"
RECOMMENDED_RN="0.84.0"

if [ "$REACT_VERSION" != "$RECOMMENDED_REACT" ] || [ "$RN_VERSION" != "$RECOMMENDED_RN" ]; then
    echo "⚠️ Updating React & React Native..."
    npm install react@$RECOMMENDED_REACT react-native@$RECOMMENDED_RN --legacy-peer-deps
fi

# 4️⃣ Ensure EAS CLI installed
if ! command -v eas >/dev/null 2>&1; then
    echo "⚠️ EAS CLI not found. Installing..."
    npm install -g eas-cli
fi

# 5️⃣ Start backend if exists
if [ -f "$BACKEND_SCRIPT" ]; then
    echo "🚀 Starting backend..."
    python3 "$BACKEND_SCRIPT" &
    BACKEND_PID=$!
else
    echo "⚠️ Backend script not found!"
fi

# 6️⃣ Build Android APK
echo "📦 Building Android APK..."
eas build --platform android --non-interactive
ANDROID_APK=$(ls ~/eas-builds/*/*/*.apk 2>/dev/null | tail -1)
[ -f "$ANDROID_APK" ] && echo "✅ Android APK built: $ANDROID_APK" || echo "⚠️ Android APK not found."

# 7️⃣ Build iOS IPA only on macOS
if [ "$OS_TYPE" = "Darwin" ]; then
    echo "📦 Building iOS IPA..."
    eas build --platform ios --non-interactive
    IOS_IPA=$(ls ~/eas-builds/*/*/*.ipa 2>/dev/null | tail -1)
    [ -f "$IOS_IPA" ] && echo "✅ iOS IPA built: $IOS_IPA" || echo "⚠️ iOS IPA not found."
fi

# 8️⃣ Collect all artifacts
mkdir -p "$DIST_DIR"
[ -f "$ANDROID_APK" ] && cp "$ANDROID_APK" "$DIST_DIR/"
[ -f "$IOS_IPA" ] && cp "$IOS_IPA" "$DIST_DIR/"

# 9️⃣ Stop backend if started
if [ ! -z "$BACKEND_PID" ]; then
    kill $BACKEND_PID
    echo "🧹 Backend stopped."
fi

echo "🚀 Build Complete! Check $DIST_DIR for APK & IPA"
