#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="$HOME/_forgemind_run"

# 1) اكتشف الجذر الحقيقي
ROOT=""
HIT="$(find "$BASE" -maxdepth 10 -type f -path '*/scripts/termux/build.sh' 2>/dev/null | head -n1 || true)"
if [[ -n "$HIT" ]]; then
  ROOT="$(cd "$(dirname "$HIT")/../.." && pwd)"
fi
if [[ -z "$ROOT" ]]; then
  HIT="$(find "$BASE" -maxdepth 10 -type f -name 'go.mod' 2>/dev/null | head -n1 || true)"
  if [[ -n "$HIT" ]]; then ROOT="$(cd "$(dirname "$HIT")" && pwd)"; fi
fi
if [[ -z "$ROOT" ]]; then
  echo "[fix] ERROR: cannot find project root under $BASE"
  exit 2
fi

echo "[fix] ROOT=$ROOT"
cd "$ROOT"

mkdir -p _logs
chmod +x scripts/termux/*.sh 2>/dev/null || true

# 2) لو server.go يتوقع index.html داخل internal/server → وفّرها
SERVER_DIR="internal/server"
WEBUI_A="internal/webui/index.html"
WEBUI_B="internal/webui/dist/index.html"

if grep -Rqs "go:embed[[:space:]]\\+index\\.html" "$SERVER_DIR"/*.go 2>/dev/null; then
  if [[ ! -f "$SERVER_DIR/index.html" ]]; then
    echo "[fix] missing internal/server/index.html (required by go:embed). Creating it..."
    if [[ -f "$WEBUI_A" ]]; then
      cp "$WEBUI_A" "$SERVER_DIR/index.html"
    elif [[ -f "$WEBUI_B" ]]; then
      cp "$WEBUI_B" "$SERVER_DIR/index.html"
    else
      echo "[fix] ERROR: cannot find a source UI file to copy."
      echo "[fix] Looked for: $WEBUI_A or $WEBUI_B"
      exit 3
    fi
  fi
fi

# 3) Go deps + build
echo "[fix] go env fallback..."
go env -w GOPROXY=direct >/dev/null 2>&1 || true
go env -w GOSUMDB=off   >/dev/null 2>&1 || true

echo "[fix] go mod tidy..."
go mod tidy 2>&1 | tee _logs/go_mod_tidy_fix.log

echo "[fix] build..."
bash scripts/termux/build.sh 2>&1 | tee _logs/build_fix.log

# 4) Verify
echo "[fix] verify..."
ls -la bin | tee _logs/bin_ls_fix.log || true
if [[ -x bin/forgemindd ]]; then
  echo "[fix] ✅ BUILT: bin/forgemindd"
  file bin/forgemindd || true
else
  echo "[fix] ❌ NOT BUILT: bin/forgemindd missing"
  echo "[fix] Check _logs/build_fix.log"
  exit 4
fi
