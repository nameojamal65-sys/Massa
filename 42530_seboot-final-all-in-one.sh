#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "[+] SEBOOT FINAL ALL-IN-ONE BUILD"

ROOT="$(pwd)"
OUT="$ROOT/dist"
BIN="$OUT/seboot.platform.final.bin"

mkdir -p "$OUT"

############################################
# 0) Sanity checks
############################################
command -v go >/dev/null || { echo "go not found"; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum not found"; exit 1; }
command -v find >/dev/null || { echo "find not found"; exit 1; }
command -v du >/dev/null || { echo "du not found"; exit 1; }

############################################
# 1) Build hardened final binary
############################################
echo "[+] Building hardened binary"
go build -ldflags="-s -w" -o "$BIN" ./cmd/seboot

############################################
# 2) Compute metrics (source tree)
############################################
echo "[+] Computing source metrics"
FILE_COUNT="$(find . -type f \
  ! -path './.git/*' \
  ! -path './dist/*' \
  ! -path './vendor/*' | wc -l | tr -d ' ')"

SRC_SIZE="$(du -sh . | awk '{print $1}')"

############################################
# 3) Compute binary metrics
############################################
BIN_SIZE="$(du -h "$BIN" | awk '{print $1}')"
BIN_SHA="$(sha256sum "$BIN" | awk '{print $1}')"

############################################
# 4) Copy final artifact to user files
############################################
USER_FILES="$HOME/seboot_artifacts"
mkdir -p "$USER_FILES"
cp -f "$BIN" "$USER_FILES/"

############################################
# 5) Report (final, authoritative)
############################################
echo
echo "========================================"
echo " SEBOOT PLATFORM — FINAL REPORT"
echo "========================================"
echo "Binary name        : seboot.platform.final.bin"
echo "Binary path        : $USER_FILES/seboot.platform.final.bin"
echo "Binary size        : $BIN_SIZE"
echo "Binary SHA256      : $BIN_SHA"
echo "----------------------------------------"
echo "Source file count  : $FILE_COUNT"
echo "Source tree size   : $SRC_SIZE"
echo "----------------------------------------"
echo "Status             : READY FOR TRANSFER"
echo "========================================"
echo
