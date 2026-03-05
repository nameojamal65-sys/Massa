#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "👑 PAI6 — NUCLEAR MASTER APK BUILDER"
echo "==================================="
sleep 1

BASE=~/pai6_final_build
SRC=~/pai6_sovereign_ui

echo
echo "📁 Verifying directories..."

if [ ! -d "$SRC" ]; then
    echo "❌ PAI6 source not found at: $SRC"
    exit 1
fi

mkdir -p "$BASE"
cd "$BASE"

echo "✅ Source located"
echo "📂 Build dir: $BASE"

echo
echo "🧹 Cleaning old builds..."
rm -rf .buildozer bin *.spec

echo
echo "📦 Syncing PAI6 source..."
rsync -a --delete "$SRC/" "$BASE/"

echo
echo "⚙️ Generating buildozer.spec..."

cat <<'SPEC' > buildozer.spec
[app]
title = PAI6 Sovereign Node
package.name = pai6node
package.domain = pai6.sovereign
source.dir = .
source.include_exts = py,kv,json,txt,png,jpg,mp4,ini,db
version = 1.0

requirements = python3,kivy,cython,flask,fastapi,requests,pillow,psutil,qrcode,opencv-python,uvicorn,jinja2

orientation = portrait
fullscreen = 1
android.permissions = INTERNET,READ_EXTERNAL_STORAGE,WRITE_EXTERNAL_STORAGE

android.api = 33
android.minapi = 24
android.archs = arm64-v8a

[buildozer]
log_level = 2
warn_on_root = 0
SPEC

echo "✅ buildozer.spec ready"

echo
echo "⚙️ Preparing environment variables..."

export ANDROIDSDK="$HOME/.buildozer/android/platform/android-sdk"
export ANDROIDNDK="$HOME/.buildozer/android/platform/android-ndk-r25b"
export JAVA_HOME=$(dirname $(dirname $(which java)))
export PATH=$JAVA_HOME/bin:$PATH

echo
echo "☕ Java:"
java -version || true

echo
echo "🐍 Python:"
python -V

echo
echo "⚙️ Installing python requirements..."

pip install --upgrade pip setuptools wheel
pip install buildozer cython

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

echo
echo "🚀 Starting NUCLEAR APK BUILD..."

buildozer android clean
buildozer -v android debug

echo
echo "==================================="
echo "🎯 BUILD FINISHED"
echo "==================================="

APK=$(ls bin/*.apk 2>/dev/null | head -n 1)

if [ -z "$APK" ]; then
    echo "❌ APK NOT FOUND — build failed"
    exit 1
else
    echo "✅ APK GENERATED SUCCESSFULLY"
    echo "📦 Location:"
    echo "$APK"
    echo
    du -h "$APK"
fi

echo
echo "👑 PAI6 APK READY — SOVEREIGN MODE"
echo "==================================="
