#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[fm] STEP 1 — Bootstrap from Downloads"

HOME_DIR="$HOME"
DL="$HOME_DIR/downloads"
RUNROOT="$HOME_DIR/_forgemind_run"

mkdir -p "$RUNROOT"

# 1) اختَر أحدث ZIP
ZIP="$(ls -t "$DL"/*.zip 2>/dev/null | head -n1 || true)"
if [ -z "$ZIP" ]; then
  echo "[fm][ERROR] لا يوجد أي zip داخل downloads"
  exit 1
fi

echo "[fm] ZIP FOUND: $ZIP"

# 2) فكّه
TS=$(date +%Y%m%d_%H%M%S)
DEST="$RUNROOT/run_$TS"
mkdir -p "$DEST"
unzip -q "$ZIP" -d "$DEST"

echo "[fm] Extracted to: $DEST"

# 3) ابحث عن الجذر (go.mod + scripts/termux)
ROOT=""
for d in $(find "$DEST" -maxdepth 5 -type d); do
  if [ -f "$d/go.mod" ] && [ -d "$d/scripts/termux" ]; then
    ROOT="$d"
    break
  fi
done

if [ -z "$ROOT" ]; then
  echo "[fm][ERROR] لم أجد جذر مشروع (go.mod + scripts/termux)"
  echo "[fm] محتوى التفريغ:"
  find "$DEST" -maxdepth 3 -type d
  exit 2
fi

echo "[fm] PROJECT ROOT FOUND:"
echo "--------------------------------"
echo "$ROOT"
echo "--------------------------------"

# 4) ثبّت الأدوات الأساسية فقط
echo "[fm] Installing minimal toolchain..."
pkg update -y
pkg install -y git golang nodejs-lts python rust make clang pkg-config openssl-tool sqlite

# 5) صلاحيات
chmod +x "$ROOT/scripts/termux/"*.sh

# 6) تقرير
echo
echo "✅ STEP 1 DONE"
echo
echo "NEXT STEP:"
echo "cd \"$ROOT\""
echo "bash scripts/termux/build.sh"
echo
