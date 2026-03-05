#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="$HOME/_forgemind_run"

if [[ ! -d "$BASE" ]]; then
  echo "[fm] ERROR: $BASE not found"
  exit 2
fi

ROOT=""
# ابحث عن go.mod + scripts/termux
HIT="$(find "$BASE" -maxdepth 6 -type f -name go.mod 2>/dev/null | head -n1 || true)"
if [[ -n "$HIT" ]]; then
  CAND="$(cd "$(dirname "$HIT")" && pwd)"
  if [[ -d "$CAND/scripts/termux" ]]; then ROOT="$CAND"; fi
fi

if [[ -z "$ROOT" ]]; then
  HIT2="$(find "$BASE" -maxdepth 8 -type f -path '*/scripts/termux/doctor.sh' 2>/dev/null | head -n1 || true)"
  if [[ -n "$HIT2" ]]; then ROOT="$(cd "$(dirname "$HIT2")/../.." && pwd)"; fi
fi

if [[ -z "$ROOT" ]]; then
  echo "[fm] ERROR: cannot find project root under $BASE"
  echo "[fm] tree:"
  find "$BASE" -maxdepth 3 -type d | sed 's|^|  |'
  exit 3
fi

echo "[fm] ROOT=$ROOT"
cd "$ROOT"

chmod +x scripts/termux/*.sh 2>/dev/null || true

mkdir -p _logs
echo "[fm] go.mod? $(test -f go.mod && echo yes || echo no)"
echo "[fm] building..."
bash scripts/termux/build.sh 2>&1 | tee _logs/build_setup.log

echo "[fm] verify bin:"
ls -la bin || true
test -x bin/forgemindd && echo "[fm] ✅ BUILT bin/forgemindd" || echo "[fm] ❌ NOT BUILT"
