#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

OUT="$HOME/sovereign_build_out"
BUNDLE_DIR="$HOME/sovereign_result_bundle"
STAMP="$(date +%Y%m%d_%H%M%S)"
ZIP_OUT="$HOME/sovereign_result_${STAMP}.zip"

need() { command -v "$1" >/dev/null 2>&1 || { echo "[!] مفقود: $1. ثبّت: pkg install $1"; exit 1; }; }
need zip
need find
need uname
need sed

if [ ! -d "$OUT" ]; then
  echo "[!] ما لقيت مجلد النتائج: $OUT"
  echo "    شغّل سكربت البناء أولاً (build_all.sh) ثم ارجع هنا."
  exit 1
fi

rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"

echo "[*] Collecting results from: $OUT"
echo "[*] Bundle dir: $BUNDLE_DIR"

cp -r "$OUT" "$BUNDLE_DIR/out"

{
  echo "=== SYSTEM INFO ==="
  date
  uname -a
  echo ""
  echo "=== TERMUX INFO ==="
  command -v termux-info >/dev/null 2>&1 && termux-info || echo "termux-info not installed"
  echo ""
  echo "=== GO INFO ==="
  command -v go >/dev/null 2>&1 && go version || echo "go not installed"
  echo ""
  echo "=== STORAGE ==="
  df -h || true
} > "$BUNDLE_DIR/system_info.txt" 2>/dev/null || true

{
  echo "=== OUTPUT TREE (files) ==="
  find "$BUNDLE_DIR/out" -maxdepth 4 -type f | sed "s|$BUNDLE_DIR/||" | sort
  echo ""
  echo "=== OUTPUT TREE (dirs) ==="
  find "$BUNDLE_DIR/out" -maxdepth 4 -type d | sed "s|$BUNDLE_DIR/||" | sort
} > "$BUNDLE_DIR/out_tree.txt"

if [ -f "$OUT/build.log" ]; then
  cp "$OUT/build.log" "$BUNDLE_DIR/build.log"
fi

echo "[*] Creating zip: $ZIP_OUT"
cd "$BUNDLE_DIR"
zip -r -q "$ZIP_OUT" .

echo ""
echo "[OK] جاهز."
echo "الملف النهائي:"
echo "$ZIP_OUT"
