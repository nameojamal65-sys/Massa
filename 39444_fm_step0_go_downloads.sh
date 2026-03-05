#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[fm] STEP 0 — go to downloads"

DL="$HOME/downloads"

if [ ! -d "$DL" ]; then
  echo "[fm] ERROR: downloads folder not found at $DL"
  exit 1
fi

cd "$DL"

echo "[fm] You are now in:"
pwd

echo
echo "[fm] ZIP files here:"
ls -lh *.zip 2>/dev/null || echo "No zip files found"

echo
echo "NEXT:"
echo "Run the bootstrap script from here."
