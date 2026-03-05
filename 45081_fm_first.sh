#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ZIP="${1:-}"
if [[ -z "${ZIP}" ]]; then
  ZIP="$(ls -t "$HOME/downloads"/forgemind_enterprise_ifc_v0.7_win_termux*.zip 2>/dev/null | head -n1 || true)"
fi
if [[ -z "${ZIP}" || ! -f "${ZIP}" ]]; then
  echo "[fm_first] ERROR: zip not found."
  echo "Usage: bash fm_first.sh /path/to/forgemind_enterprise_ifc_v0.7_win_termux.zip"
  exit 1
fi

BASE="$HOME/_forgemind_run"
TS="$(date +%Y%m%d_%H%M%S)"
RUN="$BASE/run_$TS"
mkdir -p "$RUN"
cd "$RUN"

echo "[fm_first] extracting -> $RUN"
unzip -q "$ZIP"

ROOT="$RUN/forgemind_enterprise_ifc_v0.7"
if [[ ! -d "$ROOT/scripts/termux" ]]; then
  echo "[fm_first] ERROR: cannot find project root."
  exit 1
fi

cd "$ROOT"
chmod +x scripts/termux/*.sh 2>/dev/null || true

echo "[fm_first] doctor (setup+build+health) ..."
bash scripts/termux/doctor.sh || true

echo
echo "[fm_first] next:"
echo "  bash scripts/termux/run.sh"
echo "  curl -s http://127.0.0.1:8080/health"
