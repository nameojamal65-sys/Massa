#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Tremix Bootstrap (Auto-ZIP Finder)"

HOME_DIR="$HOME"
REBUILDER="$HOME_DIR/tremix_rebuilder.py"
ZIP_TARGET="$HOME_DIR/api6.zip"

# 1) Packages
pkg update -y >/dev/null 2>&1 || true
pkg install -y python curl unzip >/dev/null 2>&1 || true

python3 -m ensurepip --upgrade >/dev/null 2>&1 || true
python3 -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1 || true

# 2) Ensure rebuilder exists
if [ ! -f "$REBUILDER" ]; then
  echo "❌ Missing: $REBUILDER"
  echo "ضع ملف tremix_rebuilder.py في الهوم أولاً."
  exit 1
fi

# 3) Find zip if api6.zip missing
if [ ! -f "$ZIP_TARGET" ]; then
  echo "🔎 api6.zip مش موجود في الهوم… بدوّر عليه"

  # Try Termux storage
  termux-setup-storage >/dev/null 2>&1 || true

  CANDIDATES=(
    "$HOME_DIR/downloads"
    "$HOME_DIR/storage/downloads"
    "/sdcard/Download"
    "/sdcard"
  )

  FOUND=""
  for d in "${CANDIDATES[@]}"; do
    if [ -d "$d" ]; then
      # prefer api6/pai6 name, else any zip
      FOUND="$(find "$d" -maxdepth 4 -type f \( -iname "*api6*.zip" -o -iname "*pai6*.zip" -o -iname "source_code*.zip" -o -iname "*.zip" \) 2>/dev/null | head -n 1 || true)"
      if [ -n "${FOUND:-}" ]; then
        break
      fi
    fi
  done

  if [ -z "${FOUND:-}" ]; then
    echo "❌ ما لقيت أي ZIP في المسارات المعروفة."
    echo "جرّب:"
    echo "  find /sdcard -maxdepth 4 -type f -iname '*.zip' 2>/dev/null"
    exit 1
  fi

  echo "✅ لقيت: $FOUND"
  cp "$FOUND" "$ZIP_TARGET"
  echo "📦 نسخته إلى: $ZIP_TARGET"
fi

# 4) Ollama (اختياري)
if command -v ollama >/dev/null 2>&1; then
  echo "🧠 Starting Ollama..."
  nohup ollama serve >/dev/null 2>&1 & disown || true
  sleep 2
  curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && echo "✅ Ollama OK" || echo "⚠️ Ollama not responding"
else
  echo "⚠️ Ollama غير موجود — السكربت اللي يعتمد عليه AI ممكن يفشل"
fi

# 5) Run rebuilder
echo "🛠 Running: tremix_rebuilder.py"
python3 "$REBUILDER"

echo "✅ Done"
