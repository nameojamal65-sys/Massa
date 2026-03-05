#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🚀 Sovereign One‑Run Master Builder"

PROJECT="$HOME/sovereign_core"
DIST="$PROJECT/dist_bin"
BUILD="$PROJECT/build_tmp"
ZIP="$PROJECT/sovereign_release.zip"

mkdir -p "$DIST" "$BUILD"

echo "📦 Installing build dependencies..."
pip install --upgrade pip pyinstaller rclone

echo "🔨 Building binary..."
cd "$PROJECT"

pyinstaller \
  --onefile \
  --clean \
  --name sovereign_core \
  boot.py \
  --distpath "$DIST" \
  --workpath "$BUILD"

echo "📦 Packaging..."
cd "$DIST"
rm -f "$ZIP"
zip -9 "$ZIP" sovereign_core

echo "☁️ Checking rclone config..."
if ! rclone listremotes | grep -q "gdrive:"; then
  echo "⚠️  Google Drive غير مهيأ — سيتم فتح الإعداد الآن"
  rclone config
fi

echo "🚀 Uploading to Google Drive..."
rclone copy "$ZIP" gdrive:/sovereign_builds -P

echo "✅ Upload completed"
echo "📁 File: sovereign_release.zip"
echo "🌐 Location: gdrive:/sovereign_builds"

echo "🏁 DONE — Ready for Google Cloud deployment"
