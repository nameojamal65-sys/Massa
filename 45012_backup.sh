#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
DATA="${DATA:-./data}"
OUT="${OUT:-_logs/backup_$(date +%Y%m%d_%H%M%S).tar.gz}"
mkdir -p _logs
tar -czf "$OUT" "$DATA/registry" "$DATA/audit.jsonl" "$DATA/index.json" 2>/dev/null || tar -czf "$OUT" "$DATA/registry" "$DATA/audit.jsonl" 2>/dev/null || tar -czf "$OUT" "$DATA/registry"
echo "BACKUP=$OUT"
