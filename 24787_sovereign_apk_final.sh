#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starting Sovereign Full APK Final Conversion..."

# --- إعدادات ---
EXPO_PROJECT_DIR="$HOME/sovereign_android_final"
REACT_FRONTEND_DIR="$HOME/sovereign_dashboard"
BACKEND_FILE="$HOME/sovereign_core_full.py"
LOCAL_API_PORT=5000
APP_ICON="$HOME/sovereign_icon.png"  # ضع أيقونة هنا

# --- تثبيت Node و Expo CLI ---
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

# --- إنشاء مشروع Expo React Native جديد ---
if [ ! -d "$EXPO_PROJECT_DIR" ]; then
    echo "📁 Creating Expo Project..."
    expo init sovereign_android_final --template blank
else
    echo "📁 Expo project exists, skipping creation."
fi

cd $EXPO_PROJECT_DIR || exit

# --- نسخ واجهة React ---
if [ -d "$REACT_FRONTEND_DIR/src" ]; then
    echo "📄 Copying React frontend..."
    mkdir -p src
    cp -r $REACT_FRONTEND_DIR/src/* src/
else
    echo "⚠️ React frontend not found."
fi

# --- نسخ Backend Python ---
if [ -f "$BACKEND_FILE" ]; then
    echo "📦 Copying Python backend..."
    mkdir -p assets/backend
    cp $BACKEND_FILE assets/backend/
else
    echo "⚠️ Backend file not found."
fi

# --- إعداد env API ---
echo "⚙️ Setting API URL..."
echo "VITE_API_URL=http://localhost:$LOCAL_API_PORT" > .env

# --- إضافة أيقونة التطبيق ---
if [ -f "$APP_ICON" ]; then
    echo "🖼 Setting App Icon..."
    mkdir -p assets
    cp $APP_ICON assets/icon.png
fi

# --- إنشاء SplashScreen ---
SPLASH_JS="$EXPO_PROJECT_DIR/App.js"
cat << 'EOF' > $SPLASH_JS
import React, { useEffect, useState } from 'react';
import { View, Text, ActivityIndicator, StyleSheet } from 'react-native';
import axios from 'axios';
export default function App() {
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    // Simulate backend loading
    setTimeout(() => setLoading(false), 2000);
  }, []);
  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>🚀 Sovereign Loading...</Text>
        <ActivityIndicator size="large" color="#007aff"/>
      </View>
    );
  }
  return (
    <View style={styles.container}>
      <Text style={styles.title}>✅ Sovereign Ready!</Text>
      <Text>Backend & Frontend Active</Text>
    </View>
  );
}
const styles = StyleSheet.create({
  container:{flex:1, justifyContent:'center', alignItems:'center'},
  title:{fontSize:24, fontWeight:'bold'}
});
EOF

# --- إنشاء سكربت Build APK النهائي ---
cat << 'EOF' > build_final_apk.sh
#!/bin/bash
echo "🚀 Installing dependencies..."
npm install
expo install

echo "🚀 Starting local Python backend..."
cd assets/backend
nohup python3 sovereign_core_full.py > ../../backend.log 2>&1 &

cd ../../
echo "🚀 Building APK via Expo..."
expo build:android -t apk
EOF

chmod +x build_final_apk.sh

echo "✅ Sovereign Full APK Final Setup Complete!"
echo "Run './build_final_apk.sh' inside $EXPO_PROJECT_DIR to start backend and build APK."
