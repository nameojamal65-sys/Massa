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
