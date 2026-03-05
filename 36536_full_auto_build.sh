#!/bin/bash

# ================================================
# Sovereign Full Auto Build Script
# ================================================

# ====== CONFIGURATION ======
EXPO_EMAIL="Nasserjawabreh9@gmail.com"
EXPO_PASSWORD="ضع_كلمة_السر_هنا"  # حط كلمة السر هنا
BUILD_DIR="$HOME/sovereign_android_full"
OUTPUT_DIR="$BUILD_DIR/build_outputs"
NODE_VERSION="18.17.1"

# ====== ENV SETUP ======
echo "🚀 Starting Sovereign Auto Build..."
cd "$BUILD_DIR" || { echo "❌ Build directory not found"; exit 1; }

# Node version check
CURRENT_NODE=$(node -v | tr -d v)
if [ "$CURRENT_NODE" != "$NODE_VERSION" ]; then
    echo "⚠️ Node.js version mismatch: $CURRENT_NODE detected, recommended $NODE_VERSION"
fi

# Install dependencies
echo "📦 Installing npm packages..."
npm install --legacy-peer-deps

# Expo CLI check
if ! command -v eas &> /dev/null; then
    echo "⚠️ EAS CLI not found. Installing..."
    npm install -g eas-cli
fi

# Login to Expo
echo "🔑 Logging in to Expo..."
echo "$EXPO_PASSWORD" | eas login --username "$EXPO_EMAIL" --password-stdin

if [ $? -ne 0 ]; then
    echo "❌ Expo login failed. Check credentials."
    exit 1
fi

# Generate EXPO_TOKEN
EXPO_TOKEN=$(eas token)
export EXPO_TOKEN
echo "✅ Expo token generated"

# ====== BACKEND ======
echo "🖥 Starting backend..."
if [ -f "./backend/main.py" ]; then
    python3 ./backend/main.py &
    BACKEND_PID=$!
else
    echo "⚠️ Backend script not found, skipping backend"
fi

# ====== BUILD ======
mkdir -p "$OUTPUT_DIR"

# Android APK
echo "📦 Building Android APK..."
eas build --platform android --non-interactive --profile production --output-dir "$OUTPUT_DIR"

# Web
echo "🌐 Building Web..."
npm run build:web --prefix ./frontend
cp -r ./frontend/build "$OUTPUT_DIR/web_build"

# ====== CLEANUP ======
if [ ! -z "$BACKEND_PID" ]; then
    echo "🛑 Stopping backend..."
    kill "$BACKEND_PID"
fi

echo "✅ Full build completed!"
echo "📁 Outputs available in $OUTPUT_DIR"
