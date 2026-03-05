#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ARCHIVE="${1:-}"
DATA="${DATA:-./data}"
if [[ -z "$ARCHIVE" ]]; then
  echo "usage: bash scripts/termux/restore.sh path/to/backup.tar.gz"
  exit 2
fi
mkdir -p "$DATA"
tar -xzf "$ARCHIVE" -C "."
echo "[restore] ok"
