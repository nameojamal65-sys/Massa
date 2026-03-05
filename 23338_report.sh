#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="${1:-$PWD}"
cd "$ROOT"
mkdir -p _logs
OUT="_logs/report_$(date +%Y%m%d_%H%M%S).txt"
{
  echo "=== FORGEMIND V5 REPORT ==="
  echo "PWD: $PWD"
  echo "date: $(date)"
  echo "uname: $(uname -a || true)"
  echo "--- versions ---"
  echo "go: $(go version 2>/dev/null || true)"
  echo "node: $(node -v 2>/dev/null || true)"
  echo "python: $(python -V 2>/dev/null || true)"
  echo "rustc: $(rustc -V 2>/dev/null || true)"
  echo "--- tree ---"
  ls -la
  echo "--- scripts ---"
  ls -la scripts/termux
  echo "--- last logs ---"
  ls -la _logs || true
} | tee "$OUT"
echo "REPORT_FILE=$OUT"
