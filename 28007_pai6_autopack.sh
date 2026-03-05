#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🚀 PAI6 — Autonomous Build System"
echo "=================================="
sleep 1

BASE=~/pai6
OUT=~/pai6_export

mkdir -p $OUT

echo "[1] Checking PAI6 Core..."
[ ! -d "$BASE" ] && echo "❌ PAI6 not found!" && exit 1

echo "✅ Core found"

echo "[2] Generating requirements.txt..."
cat <<EOF > $BASE/requirements.txt
kivy
buildozer
cython
cryptography
qrcode
opencv-python
flask
fastapi
uvicorn
jinja2
psutil
requests
pillow
EOF

echo "✅ requirements.txt created"

echo "[3] Generating auto build script..."

cat <<'EOF' > $BASE/auto_build.py
import os, tarfile, sys

print("🚀 PAI6 Auto Builder")

BASE="pai6"
ARCHIVE="pai6_full_autobuild.tar.gz"

with tarfile.open(ARCHIVE,"w:gz") as tar:
    tar.add(BASE, arcname="pai6")

print("✅ Exported:", ARCHIVE)
EOF

echo "✅ auto_build.py created"

echo "[4] Creating laptop build script..."

cat <<'EOF' > $BASE/build_auto.sh
#!/usr/bin/env bash

clear
echo "🚀 PAI6 Self Build System"
echo "=========================="

echo "[1] Installing base packages..."
sudo apt update
sudo apt install -y python3 python3-pip git zip unzip openjdk-17-jdk adb

echo "[2] Installing Buildozer..."
pip3 install --upgrade buildozer cython

echo "[3] Preparing Android SDK..."
mkdir -p ~/.buildozer/android/platform
buildozer android update

echo "[4] Installing libraries..."
pip3 install -r requirements.txt

echo "[5] Building APK..."
buildozer android debug

echo "================================="
echo "✅ APK GENERATED SUCCESSFULLY"
echo "📦 Location: bin/*.apk"
EOF

chmod +x $BASE/build_auto.sh

echo "✅ build_auto.sh created"

echo "[5] Generating buildozer.spec..."

cat <<EOF > $BASE/buildozer.spec
[app]
title = PAI6 Sovereign Node
package.name = pai6node
package.domain = pai6.sovereign
source.dir = .
source.include_exts = py,png,jpg,kv,json,txt,mp4
version = 1.0
requirements = python3,kivy
orientation = portrait
fullscreen = 1

android.permissions = INTERNET,READ_EXTERNAL_STORAGE,WRITE_EXTERNAL_STORAGE

[buildozer]
log_level = 2
warn_on_root = 0
EOF

echo "✅ buildozer.spec generated"

echo "[6] Exporting full package..."

cd ~
tar -czvf $OUT/pai6_full_autobuild.tar.gz pai6/

echo "=========================================="
echo "🎯 EXPORT COMPLETE"
echo "📦 File: $OUT/pai6_full_autobuild.tar.gz"
echo "=========================================="
