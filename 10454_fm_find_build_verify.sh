#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="$HOME/_forgemind_run"

echo "[fm] BASE=$BASE"
test -d "$BASE" || { echo "[fm] ERROR: $BASE not found"; exit 2; }

# ابحث عن أحدث مشروع حقيقي (فيه scripts/termux/build.sh)
ROOT=""
HIT="$(find "$BASE" -maxdepth 10 -type f -path '*/scripts/termux/build.sh' 2>/dev/null | sort | tail -n 1 || true)"
if [[ -n "$HIT" ]]; then
  ROOT="$(cd "$(dirname "$HIT")/../.." && pwd)"
fi

if [[ -z "$ROOT" ]]; then
  echo "[fm] ERROR: cannot find any project root with scripts/termux/build.sh"
  echo "[fm] tree:"
  find "$BASE" -maxdepth 3 -type d | sed 's|^|  |'
  exit 3
fi

echo "[fm] ROOT=$ROOT"
cd "$ROOT"

# sanity
echo "[fm] pwd=$(pwd)"
ls -la | sed -n '1,60p'

# perms
chmod +x scripts/termux/*.sh 2>/dev/null || true

# go deps (network hard mode)
go env -w GOPROXY=direct >/dev/null 2>&1 || true
go env -w GOSUMDB=off   >/dev/null 2>&1 || true

mkdir -p _logs

# build
echo "[fm] building..."
bash scripts/termux/build.sh 2>&1 | tee _logs/build_fix.log || {
  echo "[fm] BUILD FAILED. show last 120 lines:"
  tail -n 120 _logs/build_fix.log || true
  exit 4
}

# verify
echo "[fm] verify bin..."
ls -la bin || true
if [[ -x bin/forgemindd ]]; then
  echo "[fm] ✅ BUILT OK: bin/forgemindd"
  file bin/forgemindd || true
else
  echo "[fm] ❌ bin/forgemindd not found after build"
  echo "[fm] show build log tail:"
  tail -n 120 _logs/build_fix.log || true
  exit 5
fi
