#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT_DIR="$HOME/sovereign_core"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
ARCHIVE_NAME="sovereign_core_full_$(date +%Y%m%d_%H%M%S).zip"
LOG_FILE="$ROOT_DIR/build.log"

echo "🚀 Starting Sovereign MASTER BUILD..." | tee $LOG_FILE

# تجهيز المجلدات
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "📦 Collecting full system..." | tee -a $LOG_FILE

rsync -av --exclude=build --exclude=dist \
    --exclude=*.zip \
    --exclude=*.log \
    "$ROOT_DIR/" "$BUILD_DIR/" | tee -a $LOG_FILE

echo "⚙️ Building Binary Core..." | tee -a $LOG_FILE

pkg install -y python python-dev clang make patchelf zlib-dev libffi-dev

pip install --upgrade pip pyinstaller

cat > "$BUILD_DIR/entry.py" <<'PY'
import os, subprocess, sys
BASE = os.path.dirname(os.path.abspath(__file__))
os.chdir(BASE)
subprocess.call(["bash","boot.sh"])
PY

pyinstaller --onefile \
    --name sovereign_core \
    "$BUILD_DIR/entry.py" | tee -a $LOG_FILE

cp dist/sovereign_core "$DIST_DIR/"

echo "🧬 Copying full system..." | tee -a $LOG_FILE
cp -r "$BUILD_DIR" "$DIST_DIR/system"

echo "📦 Creating archive..." | tee -a $LOG_FILE
cd "$DIST_DIR"
zip -r "../$ARCHIVE_NAME" .

cd "$ROOT_DIR"

echo "📊 Building file table..." | tee -a $LOG_FILE
echo "----------------------------------------"
printf "%-55s %10s\n" "FILE" "SIZE"
echo "----------------------------------------"

TOTAL=0
COUNT=0

while read -r size file; do
  printf "%-55s %10s\n" "$file" "$size"
  TOTAL=$((TOTAL+size))
  COUNT=$((COUNT+1))
done < <(find "$DIST_DIR" -type f -exec du -b {} \;)

echo "----------------------------------------"
echo "📁 Files Count : $COUNT"
echo "💾 Total Size  : $(du -sh "$DIST_DIR" | cut -f1)"
echo "📦 Archive     : $ARCHIVE_NAME"
echo "----------------------------------------"

echo "☁️ Preparing Google Drive upload..." | tee -a $LOG_FILE

if ! command -v rclone >/dev/null 2>&1; then
    echo "📥 Installing rclone..." | tee -a $LOG_FILE
    pkg install -y rclone
fi

echo "⚠️ If this is first time, configure rclone:"
echo "   rclone config"
echo "   then create remote name: gdrive"
echo ""

read -p "🚀 Upload to Google Drive now? (y/n): " yn
if [[ "$yn" == "y" ]]; then
    rclone copy "$ARCHIVE_NAME" gdrive:/SOVEREIGN_CORE/ --progress | tee -a $LOG_FILE
    echo "✅ Upload completed." | tee -a $LOG_FILE
else
    echo "⏭ Skipped upload." | tee -a $LOG_FILE
fi

echo "🎯 MASTER BUILD COMPLETED SUCCESSFULLY"
