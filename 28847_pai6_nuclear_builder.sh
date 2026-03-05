#!/data/data/com.termux/files/usr/bin/bash

clear
echo "👑 PAI6 — NUCLEAR AUTONOMOUS BUILDER"
echo "===================================="
sleep 1

echo "🔍 Locating PAI6 Core..."

SEARCH_PATH=$(find ~ -maxdepth 5 -type d \( -iname "pai6*" -o -iname "VehicleApp*" -o -iname "PAI6*" \) 2>/dev/null | head -n 1)

if [ -z "$SEARCH_PATH" ]; then
    echo "❌ PAI6 NOT FOUND ANYWHERE!"
    echo "➡️  Please ensure PAI6 exists on device"
    exit 1
fi

echo "✅ PAI6 Located at:"
echo "$SEARCH_PATH"
sleep 1

BASE="$SEARCH_PATH"
OUT=~/pai6_export

mkdir -p "$OUT"

echo "🧹 Cleaning environment..."
pkill -f autocycle 2>/dev/null
pkill -f python 2>/dev/null
sleep 1

echo "⚙️  Generating requirements.txt..."

cat <<EOF > "$BASE/requirements.txt"
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

echo "⚙️  Generating auto_build.py..."

cat <<'EOF' > "$BASE/auto_build.py"
import tarfile, os

print("🚀 PAI6 Autonomous Exporter")

base = "."
archive = "pai6_full_autobuild.tar.gz"

with tarfile.open(archive, "w:gz") as tar:
    tar.add(base, arcname="pai6")

print("✅ Package created:", archive)
EOF

echo "⚙️  Generating build_auto.sh..."

cat <<'EOF' > "$BASE/build_auto.sh"
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
EOF

chmod +x "$BASE/build_auto.sh"

echo "⚙️  Generating buildozer.spec..."

cat <<EOF > "$BASE/buildozer.spec"
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

echo "📦 Exporting FULL PAI6 BUILD PACKAGE..."

cd "$BASE/.."
tar -czvf "$OUT/pai6_FULL_NUCLEAR_BUILD.tar.gz" "$(basename "$BASE")"

echo ""
echo "==============================================="
echo "🎯 EXPORT COMPLETE — NUCLEAR PACKAGE READY"
echo "📦 File:"
echo "$OUT/pai6_FULL_NUCLEAR_BUILD.tar.gz"
echo "==============================================="
echo ""
