#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
mkdir -p _logs
OUT="_logs/snags_capture_$(date +%Y%m%d_%H%M%S).txt"
{
  echo "=== SNAGS CAPTURE ==="
  echo "date: $(date)"
  echo "pwd: $PWD"
  echo "--- last logs ---"
  ls -la _logs || true
  echo
  for f in _logs/commission_* _logs/build.log _logs/server.log _logs/go_mod_tidy.log; do
    if [[ -f "$f" ]]; then
      echo "----- FILE: $f -----"
      sed -n '1,220p' "$f" || true
      echo
    fi
  done
} | tee "$OUT"
echo "SNAGS_FILE=$OUT"
