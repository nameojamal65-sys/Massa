#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

############################################
# ForgeMind Ultra Doctor (Termux)
# - Auto env prepare
# - Auto find ZIP
# - Auto detect project root
# - Fix deps + build + run + smoke tests
# - Produce full report on failure
############################################

# -------- knobs ----------
RUNROOT="${RUNROOT:-$HOME/_forgemind_run}"
ZIP_HINT="${ZIP_HINT:-forgemind}"         # keyword to prefer zip name
PORT="${PORT:-8080}"
BASE="${BASE:-http://127.0.0.1:${PORT}}"
TOKEN="${TOKEN:-fm_dev_token}"
KEEP_WORK="${KEEP_WORK:-1}"              # 1 keep extracted, 0 delete on success
# -------------------------

log(){ printf "[fm] %s\n" "$*"; }
die(){ printf "[fm][FATAL] %s\n" "$*" >&2; exit 1; }

need_cmd(){ command -v "$1" >/dev/null 2>&1 || return 1; }

# Save report
ts(){ date +%Y%m%d_%H%M%S; }
REPORT_DIR=""
REPORT_FILE=""

mkreport(){
  REPORT_DIR="${REPORT_DIR:-$RUNROOT/_reports}"
  mkdir -p "$REPORT_DIR"
  REPORT_FILE="$REPORT_DIR/report_$(ts).txt"
  : > "$REPORT_FILE"
}

append(){
  # shellcheck disable=SC2129
  echo "$*" | tee -a "$REPORT_FILE"
}

section(){
  append ""
  append "===================="
  append "$1"
  append "===================="
}

run(){
  # run command, tee output
  append "\$ $*"
  # shellcheck disable=SC2090
  ( "$@" ) 2>&1 | tee -a "$REPORT_FILE"
}

# ---------- env prep ----------
prepare_env(){
  section "ENV PREP"
  run pkg update -y
  run pkg upgrade -y || true
  run pkg install -y git curl wget tar unzip findutils coreutils sed grep gawk make clang pkg-config openssl-tool sqlite
  run pkg install -y golang nodejs-lts python rust
  if ! need_cmd pnpm; then
    run npm i -g pnpm
  fi
  # Useful utils
  if need_cmd dos2unix; then :; else
    # dos2unix optional; if missing we won't install extra unless needed
    true
  fi
}

# ---------- choose zip ----------
choose_zip(){
  section "ZIP DISCOVERY"
  mkdir -p "$RUNROOT"
  local candidates=()
  local d
  for d in "$HOME/downloads" "$HOME/Downloads" "$HOME"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do candidates+=("$f"); done < <(find "$d" -maxdepth 2 -type f -name "*.zip" -print0 2>/dev/null || true)
  done
  ((${#candidates[@]})) || die "No zip found. Put the pack in ~/downloads or ~/Downloads"

  # prefer name with hint
  local chosen=""
  local z bn
  for z in "${candidates[@]}"; do
    bn="$(basename "$z" | tr '[:upper:]' '[:lower:]')"
    if echo "$bn" | grep -q "$ZIP_HINT"; then chosen="$z"; break; fi
  done
  # else newest
  if [[ -z "$chosen" ]]; then
    chosen="$(ls -t "${candidates[@]}" 2>/dev/null | head -n1 || true)"
  fi
  [[ -n "$chosen" ]] || die "Failed choosing zip"
  append "ZIP=$chosen"
  echo "$chosen"
}

# ---------- unzip & root detection ----------
unzip_and_find_root(){
  section "UNZIP + ROOT DETECT"
  local zip="$1"
  local work="$RUNROOT/run_$(ts)"
  mkdir -p "$work"
  append "WORK=$work"
  run unzip -q "$zip" -d "$work"

  # detect root: must contain scripts/termux/doctor.sh and go.mod
  local root=""
  local hit=""
  hit="$(find "$work" -maxdepth 8 -type f -path '*/scripts/termux/doctor.sh' 2>/dev/null | head -n1 || true)"
  if [[ -n "$hit" ]]; then
    root="$(cd "$(dirname "$hit")/../.." && pwd)"
  fi

  # validate minimal structure
  if [[ -z "$root" ]]; then
    append "ERROR: scripts/termux/doctor.sh not found"
    append "TREE:"
    find "$work" -maxdepth 4 -type d | sed 's|^|  |' | tee -a "$REPORT_FILE"
    die "Cannot find project root"
  fi

  if [[ ! -f "$root/go.mod" ]]; then
    append "WARN: go.mod not in detected root; searching..."
    local gomod
    gomod="$(find "$root" -maxdepth 3 -type f -name 'go.mod' 2>/dev/null | head -n1 || true)"
    if [[ -n "$gomod" ]]; then
      root="$(cd "$(dirname "$gomod")" && pwd)"
    fi
  fi

  append "ROOT=$root"
  echo "$root"
}

# ---------- normalize scripts ----------
normalize_scripts(){
  section "NORMALIZE SCRIPTS"
  local root="$1"
  cd "$root"

  # chmod
  run chmod +x scripts/termux/*.sh || true

  # fix CRLF if any (cheap detection)
  if grep -RIl $'\r' scripts/termux 2>/dev/null | head -n1 >/dev/null 2>&1; then
    append "Detected CRLF in scripts; normalizing..."
    # best effort: strip \r using sed
    while IFS= read -r f; do
      run sh -c "sed -i 's/\r$//' \"$f\""
    done < <(grep -RIl $'\r' scripts/termux 2>/dev/null || true)
    run chmod +x scripts/termux/*.sh || true
  fi
}

# ---------- pnpm allow builds ----------
pnpm_allow_builds(){
  section "PNPM APPROVE BUILDS (UI deps)"
  local root="$1"
  cd "$root"

  if [[ -d ui ]]; then
    cd ui
    if [[ -f pnpm-lock.yaml ]]; then
      # install deps
      run pnpm install || true
      # approve build scripts if needed (esbuild warning)
      run pnpm approve-builds || true
    fi
  fi
}

# ---------- go deps + build ----------
go_fix_build(){
  section "GO DEPS + BUILD"
  local root="$1"
  cd "$root"

  # Fallbacks for bad networks:
  run go env -w GOPROXY=direct || true
  run go env -w GOSUMDB=off || true

  # tidy with retries
  local i
  for i in 1 2 3; do
    append "go mod tidy attempt $i"
    if go mod tidy 2>&1 | tee -a "$REPORT_FILE"; then break; fi
    sleep 1
  done

  # build binaries (prefer project's build script if exists)
  if [[ -x scripts/termux/build.sh ]]; then
    run bash scripts/termux/build.sh
  else
    mkdir -p bin
    run go build -trimpath -ldflags "-s -w" -o bin/forgemindd ./cmd/forgemind
    run go build -trimpath -ldflags "-s -w" -o bin/forgemindctl ./cmd/forgemindctl
  fi

  [[ -x ./bin/forgemindd ]] || die "Binary missing: bin/forgemindd"
  [[ -x ./bin/forgemindctl ]] || append "WARN: bin/forgemindctl not found"
}

# ---------- run server + smoke ----------
run_smoke(){
  section "RUN + SMOKE"
  local root="$1"
  cd "$root"
  mkdir -p _logs

  # kill anything on port (best effort)
  if need_cmd pkill; then
    pkill -f "forgemindd serve" >/dev/null 2>&1 || true
  fi

  # start server
  append "Starting server..."
  ./bin/forgemindd serve --addr ":${PORT}" --data "./data" --token "${TOKEN}" > _logs/server_ultra.log 2>&1 &
  local pid=$!
  append "PID=$pid"
  sleep 1

  # health
  run curl -fsS "${BASE}/health"

  # index knowledge (auth)
  run curl -fsS -X POST "${BASE}/api/knowledge/index" -H "X-Auth-Token: ${TOKEN}" -H "Content-Type: application/json" -d '{}' || true

  # registry list
  run curl -fsS "${BASE}/api/registry/list" || true

  # audit tail
  run curl -fsS "${BASE}/api/audit/tail?n=40" || true

  # queue status if exists
  run curl -fsS "${BASE}/api/queue/status" || true
  run curl -fsS "${BASE}/api/queue/last" || true

  # stop
  kill "$pid" >/dev/null 2>&1 || true
  append "Server stopped."
}

# ---------- failure bundle ----------
on_fail(){
  set +e
  section "FAILURE BUNDLE"
  append "PWD=$(pwd)"
  append "RUNROOT=$RUNROOT"
  append "--- uname ---"
  uname -a 2>&1 | tee -a "$REPORT_FILE" || true
  append "--- termux-info (first 80 lines) ---"
  termux-info 2>&1 | sed -n '1,80p' | tee -a "$REPORT_FILE" || true
  append "--- disk ---"
  df -h 2>&1 | tee -a "$REPORT_FILE" || true

  append "--- recent dirs ---"
  ls -la "$RUNROOT" 2>&1 | tee -a "$REPORT_FILE" || true

  append "--- find doctor logs ---"
  find "$RUNROOT" -maxdepth 5 -type f -name 'doctor_*.log' -o -name 'build*.log' -o -name 'server*.log' 2>/dev/null | tee -a "$REPORT_FILE" || true

  append ""
  append "REPORT_FILE=$REPORT_FILE"
  append "==== COPY-PASTE REPORT CONTENT BELOW ===="
  cat "$REPORT_FILE"
  exit 1
}

main(){
  mkdir -p "$RUNROOT"
  mkreport
  trap on_fail ERR

  section "START"
  append "date=$(date)"
  append "home=$HOME"

  prepare_env

  local zip
  zip="$(choose_zip)"

  local root
  root="$(unzip_and_find_root "$zip")"

  normalize_scripts "$root"
  pnpm_allow_builds "$root"
  go_fix_build "$root"
  run_smoke "$root"

  section "SUCCESS"
  append "ROOT=$root"
  append "Logs=$root/_logs"
  append "Try browser: termux-open-url \"${BASE}/\""
  append "REPORT_FILE=$REPORT_FILE"

  if [[ "$KEEP_WORK" == "0" ]]; then
    # keep only report
    append "KEEP_WORK=0 -> cleanup not implemented (safe default)."
  fi

  echo
  echo "✅ DONE"
  echo "ROOT: $root"
  echo "REPORT: $REPORT_FILE"
  echo "Open: ${BASE}/"
}

main
