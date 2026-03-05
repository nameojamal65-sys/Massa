#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "✅ SOVEREIGN CORE One-in-One (Termux)"

# 1) Storage access
if [ ! -d "$HOME/storage" ]; then
  echo "📦 Enabling storage access..."
  termux-setup-storage
  echo "ℹ️ إذا طلب صلاحيات من Android وافق، ثم أعد تشغيل السكربت."
fi

DL="$HOME/storage/downloads"
if [ ! -d "$DL" ]; then
  echo "❌ لم أجد مجلد Downloads: $DL"
  echo "تأكد من قبول صلاحيات التخزين ثم أعد المحاولة."
  exit 1
fi

# 2) Find zip (prefer Ultimate if exists, else Full)
ZIP=""
if ls "$DL"/Sovereign_Core_Ultimate_Package.zip >/dev/null 2>&1; then
  ZIP="$DL/Sovereign_Core_Ultimate_Package.zip"
elif ls "$DL"/Sovereign_Core_Full_Package.zip >/dev/null 2>&1; then
  ZIP="$DL/Sovereign_Core_Full_Package.zip"
else
  echo "❌ لم أجد أي ملف:"
  echo " - Sovereign_Core_Ultimate_Package.zip"
  echo " - Sovereign_Core_Full_Package.zip"
  echo "ضع الملف في Downloads ثم أعد تشغيل السكربت."
  exit 1
fi

echo "📦 Found ZIP: $ZIP"

# 3) Prep dependencies
echo "🔧 Installing base packages..."
pkg update -y >/dev/null
pkg install -y python git zip termux-tools >/dev/null

# Optional (voice/video)
echo "🔧 Optional tools (video/voice) ..."
pkg install -y ffmpeg espeak >/dev/null 2>&1 || true

# 4) Extract
WORK="$HOME/sovereign_run"
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

echo "🧩 Extracting..."
unzip -q "$ZIP"

# 5) Detect project folder
# ZIP contains top folder: sovereign_core or sovereign_core_ultimate
PROJ=""
if [ -d "sovereign_core" ]; then
  PROJ="sovereign_core"
elif [ -d "sovereign_core_ultimate" ]; then
  PROJ="sovereign_core_ultimate"
else
  # fallback: first folder
  PROJ="$(find . -maxdepth 1 -type d ! -name "." | head -n1 | sed 's|^\./||')"
fi

if [ -z "$PROJ" ] || [ ! -d "$PROJ" ]; then
  echo "❌ لم أستطع تحديد مجلد المشروع بعد فك الضغط."
  exit 1
fi

echo "📁 Project: $PROJ"
cd "$PROJ"

# 6) Install python requirements
if [ -f "requirements.txt" ]; then
  echo "🐍 Installing python requirements..."
  pip install -r requirements.txt >/dev/null
else
  echo "🐍 Installing minimal python deps..."
  pip install flask flask-socketio psutil pillow requests pyyaml cryptography >/dev/null 2>&1 || true
fi

# 7) Run
echo "🚀 Starting..."
chmod +x autostart.sh >/dev/null 2>&1 || true

# Open dashboard after short delay
( sleep 2; termux-open-url "http://127.0.0.1:8080" >/dev/null 2>&1 || true ) &

# Start server
if [ -f "autostart.sh" ]; then
  ./autostart.sh
else
  python -m ui.app
fi
