#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🏛️ SOVEREIGN CORE — Platform Enterprise One-Click (Termux)"

# Enable storage access
if [ ! -d "$HOME/storage" ]; then
  termux-setup-storage
  echo "ℹ️ وافق على الصلاحيات ثم أعد تشغيل السكربت."
  exit 0
fi

DL="$HOME/storage/downloads"
if [ ! -d "$DL" ]; then
  echo "❌ Downloads not found: $DL"
  exit 1
fi

# Find ZIP
ZIP=""
for name in \
  "Sovereign_Core_Platform_Enterprise_OneClick.zip" \
  "Sovereign_Core_Platform_UltimatePlusPlus.zip" \
  "Sovereign_Core_Ultimate_Package.zip" \
  "Sovereign_Core_Full_Package.zip"
do
  if [ -f "$DL/$name" ]; then ZIP="$DL/$name"; break; fi
done

if [ -z "$ZIP" ]; then
  echo "❌ لم أجد ZIP في Downloads."
  echo "ضع أحد ملفات SOVEREIGN CORE في Downloads ثم أعد المحاولة."
  exit 1
fi

echo "📦 Using ZIP: $ZIP"

# Base packages
pkg update -y
pkg install -y python git zip termux-tools openssl
# Optional media
pkg install -y ffmpeg espeak >/dev/null 2>&1 || true

python -m pip install --upgrade pip >/dev/null 2>&1 || true

WORK="$HOME/sovereign_platform_run"
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

echo "🧩 Extracting..."
unzip -q "$ZIP"

# Detect extracted folder
PROJ=""
if [ -d "sovereign_core_platform_enterprise" ]; then
  PROJ="sovereign_core_platform_enterprise"
elif [ -d "sovereign_core_platform" ]; then
  PROJ="sovereign_core_platform"
elif [ -d "sovereign_core_ultimate" ]; then
  PROJ="sovereign_core_ultimate"
elif [ -d "sovereign_core" ]; then
  PROJ="sovereign_core"
else
  PROJ="$(find . -maxdepth 1 -type d ! -name "." | head -n1 | sed 's|^\./||')"
fi

if [ -z "$PROJ" ] || [ ! -d "$PROJ" ]; then
  echo "❌ لم أستطع تحديد مجلد المشروع."
  exit 1
fi

echo "📁 Project: $PROJ"
cd "$PROJ"

# Doctor (auto install python deps + generate keys)
if [ -f "scripts/platform_doctor.sh" ]; then
  bash scripts/platform_doctor.sh
else
  # fallback
  pip install -r requirements.txt >/dev/null 2>&1 || true
fi

# Init platform if available
if [ -f "scripts/init_platform.sh" ]; then
  bash scripts/init_platform.sh
fi

# Local manifest
SHA=$(sha256sum "$ZIP" | awk '{print $1}')
python - <<PY
import json, os, subprocess, time
from pathlib import Path

def count_files():
    return int(subprocess.check_output("find . -type f | wc -l", shell=True).decode().strip())

def count_lines():
    cmd = r'find . -type f \( -name "*.py" -o -name "*.sh" -o -name "*.yml" -o -name "*.md" -o -name "*.html" -o -name "*.yaml" -o -name "*.txt" \) -exec wc -l {} + | tail -n1 | awk "{print \$1}"'
    return int(subprocess.check_output(cmd, shell=True).decode().strip())

m = {
  "name": "SOVEREIGN CORE — Local Manifest",
  "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
  "files": count_files(),
  "lines": count_lines(),
  "zip_sha256": os.environ.get("ZIP_SHA","")
}
Path("logs").mkdir(exist_ok=True)
with open("logs/manifest_local.json","w",encoding="utf-8") as f:
    json.dump(m,f,ensure_ascii=False,indent=2)
print("✅ Local manifest generated: logs/manifest_local.json")
PY

# Open UI
( sleep 2; termux-open-url "http://127.0.0.1:8080" >/dev/null 2>&1 || true ) &

echo "🚀 Starting..."
chmod +x autostart.sh >/dev/null 2>&1 || true
if [ -f "autostart.sh" ]; then
  ./autostart.sh
else
  python -m ui.app
fi
