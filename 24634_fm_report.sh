#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="${BASE:-$HOME/_forgemind_run}"
DO_BUILD="${DO_BUILD:-0}"   # 1 = حاول يبني
DO_RUN="${DO_RUN:-0}"       # 1 = حاول يشغل + health
PORT="${PORT:-8080}"
TOKEN="${TOKEN:-fm_dev_token}"
BASEURL="${BASEURL:-http://127.0.0.1:${PORT}}"

ts(){ date +%Y%m%d_%H%M%S; }
say(){ echo "[report] $*"; }

mkdir -p "$BASE/_reports"
OUT="$BASE/_reports/report_$(ts).txt"
touch "$OUT"

# find latest root with go.mod + scripts/termux/build.sh
find_root(){
  local hit
  hit="$(find "$BASE" -maxdepth 12 -type f -path '*/scripts/termux/build.sh' 2>/dev/null | sort | tail -n 1 || true)"
  if [[ -n "$hit" ]]; then
    (cd "$(dirname "$hit")/../.." && pwd)
    return 0
  fi
  hit="$(find "$BASE" -maxdepth 12 -type f -name go.mod 2>/dev/null | sort | tail -n 1 || true)"
  if [[ -n "$hit" ]]; then
    (cd "$(dirname "$hit")" && pwd)
    return 0
  fi
  return 1
}

ROOT="$(find_root || true)"

{
  echo "=== FORGEMIND FULL REPORT $(ts) ==="
  echo "HOME=$HOME"
  echo "BASE=$BASE"
  echo "ROOT=${ROOT:-<not found>}"
  echo

  echo "--- SYSTEM ---"
  echo "date: $(date)"
  echo "uname: $(uname -a 2>/dev/null || true)"
  echo "termux-info (top):"
  termux-info 2>/dev/null | sed -n '1,80p' || true
  echo

  echo "--- VERSIONS ---"
  echo "bash: $(bash --version 2>/dev/null | head -n1 || true)"
  echo "go: $(go version 2>/dev/null || true)"
  echo "node: $(node -v 2>/dev/null || true)"
  echo "npm: $(npm -v 2>/dev/null || true)"
  echo "pnpm: $(pnpm -v 2>/dev/null || true)"
  echo "python: $(python -V 2>/dev/null || true)"
  echo "rustc: $(rustc -V 2>/dev/null || true)"
  echo

  echo "--- DISK ---"
  df -h 2>/dev/null || true
  echo

  echo "--- NETWORK (best effort) ---"
  (ping -c 1 1.1.1.1 2>/dev/null | head -n2) || true
  (curl -I -m 5 -sS https://example.com | head -n3) || true
  echo

  echo "--- BASE TREE ---"
  ls -la "$BASE" 2>/dev/null || true
  echo

  if [[ -n "${ROOT:-}" ]]; then
    echo "=== PROJECT ROOT INSPECTION ==="
    echo "PWD=$ROOT"
    echo "--- TOP ---"
    (cd "$ROOT" && ls -la | sed -n '1,120p') || true
    echo

    echo "--- EXPECTED MARKERS ---"
    echo "go.mod: $(test -f "$ROOT/go.mod" && echo yes || echo no)"
    echo "scripts/termux: $(test -d "$ROOT/scripts/termux" && echo yes || echo no)"
    echo "build.sh: $(test -f "$ROOT/scripts/termux/build.sh" && echo yes || echo no)"
    echo "doctor.sh: $(test -f "$ROOT/scripts/termux/doctor.sh" && echo yes || echo no)"
    echo

    echo "--- BIN ---"
    (cd "$ROOT" && ls -la bin 2>/dev/null) || echo "no bin dir"
    (cd "$ROOT" && file bin/forgemindd 2>/dev/null) || true
    echo

    echo "--- LOGS DIR ---"
    (cd "$ROOT" && ls -la _logs 2>/dev/null | tail -n 80) || echo "no _logs dir"
    echo

    echo "--- LAST LOG SNIPPETS (best effort) ---"
    (cd "$ROOT" && for f in $(ls -t _logs/*.log 2>/dev/null | head -n 4); do
      echo "----- $f (head) -----"
      sed -n '1,160p' "$f" || true
      echo "----- $f (tail) -----"
      tail -n 120 "$f" || true
      echo
    done) || true
    echo

    if [[ "$DO_BUILD" == "1" ]]; then
      echo "=== BUILD ATTEMPT ==="
      (cd "$ROOT" && chmod +x scripts/termux/*.sh 2>/dev/null || true)
      (cd "$ROOT" && go env -w GOPROXY=direct 2>/dev/null || true)
      (cd "$ROOT" && go env -w GOSUMDB=off 2>/dev/null || true)

      (cd "$ROOT" && mkdir -p _logs)
      echo "[build] running scripts/termux/build.sh"
      (cd "$ROOT" && bash scripts/termux/build.sh 2>&1 | tee _logs/report_build.log) || true
      echo
      echo "[build] bin:"
      (cd "$ROOT" && ls -la bin 2>/dev/null) || true
      (cd "$ROOT" && file bin/forgemindd 2>/dev/null) || true
      echo
    fi

    if [[ "$DO_RUN" == "1" ]]; then
      echo "=== RUN + HEALTH ATTEMPT ==="
      (cd "$ROOT" && mkdir -p _logs)
      echo "[run] start server..."
      (cd "$ROOT" && TOKEN="$TOKEN" DATA="./data" ./bin/forgemindd serve --addr ":$PORT" --data "./data" --token "$TOKEN" > _logs/report_server.log 2>&1 & echo $! > _logs/report_server.pid) || true
      sleep 1
      echo "[run] port check:"
      (ss -ltnp 2>/dev/null | grep ":$PORT" || netstat -ltnp 2>/dev/null | grep ":$PORT" || echo "NOT LISTENING") || true
      echo "[run] health:"
      (curl -m 5 -sS -v "$BASEURL/health" 2>&1 | tail -n 80) || true
      echo "[run] server log tail:"
      (cd "$ROOT" && tail -n 160 _logs/report_server.log 2>/dev/null) || true
      echo "[run] stop server..."
      if [[ -f "$ROOT/_logs/report_server.pid" ]]; then
        kill "$(cat "$ROOT/_logs/report_server.pid")" 2>/dev/null || true
      fi
      echo
    fi
  fi

  echo "=== REPORT FILE ==="
  echo "$OUT"
} | tee "$OUT"

echo
echo "===== انسخ النص بين BEGIN/END وأرسله لي ====="
echo "----- BEGIN REPORT -----"
cat "$OUT"
echo "----- END REPORT -----"
