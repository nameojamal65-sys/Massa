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
