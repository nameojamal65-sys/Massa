#!/usr/bin/env bash
clear
echo "🚀 PAI6 Self Building Engine"
echo "============================="

sudo apt update
sudo apt install -y python3 python3-pip git zip unzip openjdk-17-jdk adb

pip3 install --upgrade buildozer cython

pip3 install -r requirements.txt

buildozer android clean
buildozer android debug

echo "===================================="
echo "✅ APK GENERATED SUCCESSFULLY"
echo "📦 Location: bin/*.apk"
echo "===================================="
