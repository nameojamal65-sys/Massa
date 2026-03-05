#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ====== Paths (عدّلها فقط لو كنت مستخدم مسارات مختلفة) ======
OUT="$HOME/sovereign_build_out"
WORK="$HOME/sovereign_build_workspace"
DL="$HOME/storage/downloads"

STAMP="$(date +%Y%m%d_%H%M%S)"
REL_NAME="ForgeMind_Sovereign_Enterprise_${STAMP}"
REL_DIR="$HOME/${REL_NAME}"
ARCHIVE="$DL/${REL_NAME}.zip"

# ====== Checks ======
need() { command -v "$1" >/dev/null 2>&1 || { echo "[!] Missing: $1 (install: pkg install $1)"; exit 1; }; }
need zip
need find
need sed
need awk
need sha256sum || true

if [ ! -d "$DL" ]; then
  echo "[!] Downloads not accessible. Run: termux-setup-storage"
  exit 1
fi

if [ ! -d "$OUT" ]; then
  echo "[!] Build output not found: $OUT"
  echo "    Run your build script first to generate binaries."
  exit 1
fi

# ====== Prepare release structure ======
rm -rf "$REL_DIR"
mkdir -p "$REL_DIR"/{bin,webui,api,config,scripts,docs,logs,meta,assets}

echo "[*] Release dir: $REL_DIR"
echo "[*] Output dir : $OUT"
echo "[*] Work dir   : $WORK"
echo "[*] Archive    : $ARCHIVE"

# ====== 1) Collect binaries ======
echo "[1/6] Collecting binaries from build output..."

# معيار executable: ملفات فيها +x (وأحياناً Go binaries تكون +x)
# نجمع من out كل الملفات التنفيذية
find "$OUT" -type f -perm -u+x 2>/dev/null | while read -r f; do
  # تجاهل ملفات نصية محتملة
  base="$(basename "$f")"
  dest="$REL_DIR/bin/$base"

  # منع التصادم بالأسماء
  if [ -e "$dest" ]; then
    # أضف suffix من المسار
    suffix="$(echo "$f" | sed 's#^'"$OUT"'##; s#[/ ]#_#g')"
    dest="$REL_DIR/bin/${base}${suffix}"
  fi

  cp -f "$f" "$dest"
done

# لو ما لقى أي executable، خذ كل الملفات من OUT كخطة بديلة
if [ -z "$(ls -A "$REL_DIR/bin" 2>/dev/null || true)" ]; then
  echo "[!] No executable files detected in $OUT. Copying full output tree instead..."
  mkdir -p "$REL_DIR/meta/out_full"
  cp -r "$OUT" "$REL_DIR/meta/out_full/"
fi

# ====== 2) Collect logs/build artifacts ======
echo "[2/6] Collecting logs/artifacts..."
[ -f "$OUT/build.log" ] && cp -f "$OUT/build.log" "$REL_DIR/logs/" || true
[ -f "$OUT/out_tree.txt" ] && cp -f "$OUT/out_tree.txt" "$REL_DIR/logs/" || true
[ -f "$OUT/system_info.txt" ] && cp -f "$OUT/system_info.txt" "$REL_DIR/logs/" || true

# ====== 3) Collect Web UI / Server / API (best effort) ======
echo "[3/6] Searching workspace for webui/server/scripts/config..."

if [ -d "$WORK" ]; then
  # WebUI candidates
  find "$WORK" -maxdepth 5 -type d \( -iname "webui" -o -iname "ui" -o -iname "dashboard" -o -iname "frontend" \) 2>/dev/null | head -n 5 | while read -r d; do
    name="$(basename "$d")"
    cp -r "$d" "$REL_DIR/webui/$name" 2>/dev/null || true
  done

  # Server/API candidates
  find "$WORK" -maxdepth 6 -type d \( -iname "server" -o -iname "api" -o -iname "internal" \) 2>/dev/null | head -n 10 | while read -r d; do
    # لا ننسخ internal كاملة إذا كانت ضخمة؛ نلتقط ملفات تشغيل شائعة فقط
    find "$d" -maxdepth 3 -type f \( -iname "*.yaml" -o -iname "*.yml" -o -iname "*.json" -o -iname "*.toml" -o -iname "*.env*" -o -iname "Dockerfile*" -o -iname "docker-compose*.yml" \) 2>/dev/null \
      | while read -r f; do
          cp -f "$f" "$REL_DIR/config/" 2>/dev/null || true
        done
  done

  # Scripts candidates
  find "$WORK" -maxdepth 6 -type d -iname "scripts" 2>/dev/null | head -n 10 | while read -r d; do
    cp -r "$d" "$REL_DIR/scripts/$(basename "$d")" 2>/dev/null || true
  done
fi

# ====== 4) Create runner scripts ======
echo "[4/6] Creating run scripts..."

cat > "$REL_DIR/run_core.sh" <<'RUNEOF'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
echo "[*] Running from: $DIR"
echo "[*] Binaries available:"
ls -la "$DIR/bin" || true
echo ""
echo "[!] اختر الباينري الصحيح للتشغيل:"
echo "مثال:"
echo "  $DIR/bin/<binary_name> --help"
RUNEOF
chmod +x "$REL_DIR/run_core.sh" || true

cat > "$REL_DIR/README.txt" <<'REOF'
ForgeMind Sovereign Enterprise Bundle

- bin/     : compiled binaries (core/executor/server/etc)
- webui/   : UI/dashboard assets if found
- api/     : reserved
- config/  : detected configs (yaml/json/env/docker)
- scripts/ : utility scripts if found
- logs/    : build logs + system info
- meta/    : manifests / hashes

To run:
  ./run_core.sh
REOF

# ====== 5) Manifest + Hashes ======
echo "[5/6] Generating manifest + hashes..."

{
  echo "name: $REL_NAME"
  echo "created: $(date -Iseconds)"
  echo "termux_user: $(whoami 2>/dev/null || echo unknown)"
  echo "pwd: $(pwd)"
  echo "out_dir: $OUT"
  echo "work_dir: $WORK"
} > "$REL_DIR/meta/manifest.txt"

# file list
find "$REL_DIR" -type f | sed "s#^$REL_DIR/##" | sort > "$REL_DIR/meta/file_list.txt"

# sha256 (إذا متوفر)
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$REL_DIR" && find . -type f -not -path "./meta/*" -print0 | xargs -0 sha256sum) > "$REL_DIR/meta/sha256sums.txt" || true
else
  echo "[!] sha256sum not available; skipping hashes" > "$REL_DIR/meta/sha256sums.txt"
fi

# ====== 6) Zip into Downloads ======
echo "[6/6] Creating archive..."
rm -f "$ARCHIVE"
cd "$HOME"
zip -r -q "$ARCHIVE" "$REL_NAME"

echo ""
echo "[OK] Platform bundle ready:"
echo "$ARCHIVE"
echo ""
echo "Tip: share it with:"
echo "  termux-share -a \"$ARCHIVE\""
