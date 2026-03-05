#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ============ Config ============
RUNROOT="${RUNROOT:-$HOME/_forgemind_run}"
ZIP_HINT="${ZIP_HINT:-forgemind}"     # كلمة تساعدنا نلاقي الzip
PORT="${PORT:-8080}"
# =================================

log(){ echo "[fm] $*"; }

log "Termux env prepare..."

# --- Packages ---
pkg update -y >/dev/null
pkg upgrade -y >/dev/null || true

# essentials
pkg install -y git curl wget tar unzip findutils coreutils sed grep gawk make clang pkg-config openssl-tool sqlite >/dev/null

# languages/toolchains
pkg install -y golang nodejs-lts python rust >/dev/null

# pnpm (needed by UI build in some packs)
if ! command -v pnpm >/dev/null 2>&1; then
  npm i -g pnpm >/dev/null
fi

# --- Choose ZIP automatically ---
mkdir -p "$RUNROOT"
cd "$HOME"

# candidates: downloads or current dir
CAND1="$HOME/downloads"
CAND2="$HOME/Downloads"
CAND3="$HOME"

ZIPS=()
for d in "$CAND1" "$CAND2" "$CAND3"; do
  if [[ -d "$d" ]]; then
    while IFS= read -r -d '' f; do ZIPS+=("$f"); done < <(find "$d" -maxdepth 2 -type f -name "*.zip" -print0 2>/dev/null || true)
  fi
done

if [[ ${#ZIPS[@]} -eq 0 ]]; then
  log "ERROR: ما لقيت أي zip على الجهاز. حط الحزمة في downloads."
  exit 1
fi

# prefer a zip that contains ZIP_HINT in name, else pick newest
CHOSEN=""
for z in "${ZIPS[@]}"; do
  bn="$(basename "$z" | tr '[:upper:]' '[:lower:]')"
  if echo "$bn" | grep -q "$ZIP_HINT"; then
    CHOSEN="$z"
    break
  fi
done

if [[ -z "$CHOSEN" ]]; then
  # newest by mtime
  CHOSEN="$(ls -t "${ZIPS[@]}" 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$CHOSEN" ]]; then
  log "ERROR: فشل اختيار zip."
  exit 1
fi

log "ZIP chosen: $CHOSEN"

# --- Clean target run dir ---
WORK="$RUNROOT/run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK"
cd "$WORK"

log "Unzipping into: $WORK"
unzip -q "$CHOSEN"

# --- Detect project root (must have scripts/termux/doctor.sh) ---
ROOT=""
# 1) check top-level folders
for d in ./*; do
  if [[ -d "$d/scripts/termux" && -f "$d/scripts/termux/doctor.sh" ]]; then
    ROOT="$(cd "$d" && pwd)"
    break
  fi
done

# 2) deep search
if [[ -z "$ROOT" ]]; then
  HIT="$(find "$WORK" -maxdepth 6 -type f -path '*/scripts/termux/doctor.sh' 2>/dev/null | head -n1 || true)"
  if [[ -n "$HIT" ]]; then
    ROOT="$(cd "$(dirname "$HIT")/../.." && pwd)"
  fi
fi

if [[ -z "$ROOT" ]]; then
  log "ERROR: ما لقيت scripts/termux/doctor.sh داخل الحزمة."
  log "افحص محتوى المجلد: $WORK"
  find "$WORK" -maxdepth 3 -type d | sed 's|^|  |'
  exit 1
fi

log "PROJECT ROOT: $ROOT"
cd "$ROOT"

# --- Permissions ---
chmod +x scripts/termux/*.sh 2>/dev/null || true

# --- Print quick sanity ---
log "Top tree:"
ls -la | sed -n '1,80p'

log "Termux scripts:"
ls -la scripts/termux

# --- Run doctor ---
log "Running doctor..."
bash scripts/termux/doctor.sh || {
  log "doctor FAILED. Showing last log summary if exists:"
  ls -la _logs 2>/dev/null || true
  if ls _logs/doctor_*.log >/dev/null 2>&1; then
    LAST="$(ls -t _logs/doctor_*.log | head -n1)"
    log "Last doctor log: $LAST"
    sed -n '1,220p' "$LAST" || true
  fi
  exit 2
}

log "OK ✅"
log "If server is up, open: http://127.0.0.1:${PORT}/"
log "ROOT kept at: $ROOT"
log "Logs: $ROOT/_logs"
