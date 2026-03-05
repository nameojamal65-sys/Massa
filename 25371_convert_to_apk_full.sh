#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starting Full APK Conversion for Sovereign System..."

# --- إعدادات ---
EXPO_PROJECT_DIR="$HOME/sovereign_android_full"
REACT_FRONTEND_DIR="$HOME/sovereign_dashboard"
BACKEND_FILE="$HOME/sovereign_core_full.py"
LOCAL_API_PORT=5000

# --- تثبيت Node و Expo CLI إذا غير موجود ---
if ! command -v node &> /dev/null; then
    echo "📦 Installing NodeJS..."
    pkg install nodejs -y
fi

if ! command -v npm &> /dev/null; then
    echo "📦 Installing npm..."
    pkg install npm -y
fi

if ! command -v expo &> /dev/null; then
    echo "📦 Installing Expo CLI..."
    npm install -g expo-cli
fi

# --- إنشاء مشروع Expo React Native إذا غير موجود ---
if [ ! -d "$EXPO_PROJECT_DIR" ]; then
    echo "📁 Creating Expo React Native Project..."
    expo init sovereign_android_full --template blank
else
    echo "📁 Expo project already exists, skipping creation."
fi

cd $EXPO_PROJECT_DIR || exit

# --- نسخ واجهة React الحالية ---
if [ -d "$REACT_FRONTEND_DIR/src" ]; then
    echo "📄 Copying React frontend..."
    mkdir -p src
    cp -r $REACT_FRONTEND_DIR/src/* src/
else
    echo "⚠️ React frontend not found at $REACT_FRONTEND_DIR/src"
fi

# --- نسخ backend Python داخل assets ---
if [ -f "$BACKEND_FILE" ]; then
    echo "📦 Copying Python backend..."
    mkdir -p assets/backend
    cp $BACKEND_FILE assets/backend/
else
    echo "⚠️ Backend file not found at $BACKEND_FILE"
fi

# --- إنشاء env للـ API المحلي داخل التطبيق ---
echo "⚙️ Setting API URL for local backend..."
echo "VITE_API_URL=http://localhost:$LOCAL_API_PORT" > .env

# --- إنشاء سكربت build APK متكامل ---
echo "🔧 Creating full build script..."
cat << 'EOF' > build_full_apk.sh
#!/bin/bash
echo "🚀 Installing dependencies..."
npm install
expo install

echo "🚀 Starting local backend in Termux/Pydroid..."
# سيشغل Flask server داخل assets/backend
cd assets/backend
nohup python3 sovereign_core_full.py > ../../backend.log 2>&1 &

cd ../../
echo "🚀 Building APK via Expo..."
expo build:android -t apk
EOF

chmod +x build_full_apk.sh

echo "✅ Full Conversion Complete!"
echo "Run './build_full_apk.sh' inside $EXPO_PROJECT_DIR to start backend and build the APK."
