#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_build_workspace"
ARCHIVE="$HOME/sovereign_archive_$(date +%Y%m%d_%H%M%S)"
CLEAN="$HOME/sovereign_clean_tmp"

echo ""
echo "🛡️  SOVEREIGN WORKSPACE SANITIZER v1.0"
echo "======================================"
echo "ROOT    : $ROOT"
echo "ARCHIVE : $ARCHIVE"
echo ""

mkdir -p "$ARCHIVE"
mkdir -p "$CLEAN"

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -d "$ROOT/$src" ]; then
    echo "✔ Keeping: $src"
    cp -r "$ROOT/$src" "$CLEAN/$dst"
  else
    echo "⚠ Missing: $src"
  fi
}

# Reference builds
copy_if_exists "forgemind_final_termux" "forgemind"
copy_if_exists "atlas_final_stage8_stage9_all_in_one" "atlas"
copy_if_exists "sovereign-engine" "sovereign-engine"
copy_if_exists "AegisSupervisorEngine_PRODUCTION_ENTERPRISE_20260126" "aegis"
copy_if_exists "astrolabe_full_release_v1_2_abc" "astrolabe"

echo ""
echo "[1/3] Archiving old workspace..."
mv "$ROOT"/* "$ARCHIVE"/

echo "[2/3] Restoring clean workspace..."
mv "$CLEAN"/* "$ROOT"/
rmdir "$CLEAN"

echo "[3/3] Final structure:"
ls -lah "$ROOT"

echo ""
echo "✅ SOVEREIGN SANITIZATION COMPLETE"
echo "📦 Archive saved at: $ARCHIVE"
echo ""
