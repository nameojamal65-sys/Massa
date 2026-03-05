#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🧾 Sovereign Collector (Termux) — Inventory + Manifest + Logs"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$HOME/sovereign_collect_$TS"
mkdir -p "$OUT"

# ---------- Helpers ----------
run() { echo -e "\n### $*\n" >> "$OUT/REPORT.txt"; ( "$@" ) >> "$OUT/REPORT.txt" 2>&1 || true; }
runsh() { echo -e "\n### $*\n" >> "$OUT/REPORT.txt"; ( bash -lc "$*" ) >> "$OUT/REPORT.txt" 2>&1 || true; }

# ---------- System snapshot ----------
echo "== SYSTEM ==" > "$OUT/REPORT.txt"
runsh "uname -a"
runsh "termux-info || true"
runsh "date"
runsh "id"
runsh "pwd"
runsh "df -h"
runsh "free -h || true"
runsh "top -b -n 1 | head -n 30 || true"

# ---------- Toolchain versions ----------
echo -e "\n== TOOLCHAINS ==" >> "$OUT/REPORT.txt"
for cmd in python python3 pip pip3 node npm go rustc cargo gcc g++ make cmake ffmpeg ffprobe espeak espeak-ng openssl git curl wget; do
  runsh "$cmd --version || $cmd -version || $cmd -V || true"
done

# ---------- Discover project roots ----------
echo -e "\n== DISCOVERY ==" >> "$OUT/REPORT.txt"
CANDIDATES=(
  "$HOME/sovereign_core_platform_enterprise"
  "$HOME/sovereign_core_platform"
  "$HOME/sovereign_core_ultimate"
  "$HOME/sovereign_core"
  "$HOME/ForgeMind_Sovereign_Enterprise"
  "$HOME/sovereign_platform_run"
  "$HOME/sovereign_run"
  "$HOME"
)

FOUND=()
for c in "${CANDIDATES[@]}"; do
  [ -d "$c" ] || continue
  # heuristic: contains autostart.sh or docker-compose or ui/ or api/ or bin/
  if find "$c" -maxdepth 3 -type f \( -name "autostart.sh" -o -name "docker-compose.yml" -o -name "Dockerfile" -o -name "run_core.sh" -o -name "*.service" \) 2>/dev/null | head -n 1 | grep -q .; then
    FOUND+=("$c")
  fi
done

# also search for common folder names (limited depth for speed)
runsh "find $HOME -maxdepth 4 -type d \\( -name 'sovereign_core*' -o -name '*Sovereign*' -o -name '*ForgeMind*' \\) 2>/dev/null | head -n 200"

if [ ${#FOUND[@]} -eq 0 ]; then
  echo "⚠️ لم أجد جذر واضح تلقائيًا. سأستخدم HOME كمرجع واسع (قد يكون كبيرًا)." | tee -a "$OUT/REPORT.txt"
  FOUND=("$HOME")
fi

printf "%s\n" "${FOUND[@]}" > "$OUT/ROOTS.txt"
echo -e "\nRoots:\n$(cat "$OUT/ROOTS.txt")" >> "$OUT/REPORT.txt"

# ---------- Network / processes ----------
echo -e "\n== NETWORK ==" >> "$OUT/REPORT.txt"
runsh "ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null || true"
runsh "ps -ef | grep -E 'python|flask|gunicorn|uvicorn|node|nginx|forge|sovereign|worker' | grep -v grep || true"
runsh "lsof -i -P -n 2>/dev/null | head -n 200 || true"

# ---------- Per-root collection ----------
mkdir -p "$OUT/roots"
ROOT_INDEX=0

for R in "${FOUND[@]}"; do
  ROOT_INDEX=$((ROOT_INDEX+1))
  SAFE_NAME="root_$ROOT_INDEX"
  DEST="$OUT/roots/$SAFE_NAME"
  mkdir -p "$DEST"

  echo -e "\n== ROOT $ROOT_INDEX: $R ==" >> "$OUT/REPORT.txt"

  # Tree (best effort)
  if command -v tree >/dev/null 2>&1; then
    runsh "tree -a -L 6 '$R' | head -n 4000"
  else
    runsh "find '$R' -maxdepth 6 -print | head -n 4000"
  fi

  # Disk usage
  runsh "du -sh '$R' 2>/dev/null || true"
  runsh "find '$R' -maxdepth 4 -type d -print0 2>/dev/null | xargs -0 -I{} sh -c 'du -sh \"{}\" 2>/dev/null' | sort -hr | head -n 60 || true"

  # File inventory + hashes (limited to reasonable count)
  runsh "find '$R' -type f 2>/dev/null | head -n 8000 > '$DEST/files.txt'"

  # Count files
  runsh "wc -l '$DEST/files.txt'"

  # Lines of code
  runsh "python - <<'PY'\nimport pathlib, sys\np=pathlib.Path(r'''$R''')\nexts={'.py','.sh','.js','.ts','.tsx','.jsx','.yml','.yaml','.md','.html','.css','.toml','.json'}\nfiles=[f for f in p.rglob('*') if f.is_file() and f.suffix.lower() in exts]\nlines=0\nfor f in files:\n  try:\n    lines += f.read_text(errors='ignore').count('\\n')+1\n  except:\n    pass\nprint('LOC_FILES', len(files))\nprint('LOC_LINES', lines)\nPY"

  # SHA256 for key files
  runsh "find '$R' -type f \\( -name 'autostart.sh' -o -name 'run_core.sh' -o -name 'docker-compose.yml' -o -name 'Dockerfile' -o -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.yaml' -o -name '*.yml' \\) 2>/dev/null | head -n 2500 | while read -r f; do sha256sum \"$f\"; done > '$DEST/sha256_selected.txt' || true"

  # Capture configs and entrypoints (copy only small text files)
  mkdir -p "$DEST/snippets"
  runsh "find '$R' -maxdepth 4 -type f \\( -name '*.env*' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.toml' -o -name '*.ini' -o -name '*.conf' -o -name 'README*' -o -name 'run*.sh' -o -name 'auto*.sh' -o -name 'autostart.sh' \\) -size -512k 2>/dev/null | head -n 400 | while read -r f; do d='$DEST/snippets'\"$(dirname \"${f#$R}\")\"; mkdir -p \"$d\"; cp -f \"$f\" \"$d/\"; done || true"

  # Logs (copy only small recent logs)
  mkdir -p "$DEST/logs"
  runsh "find '$R' -type f \\( -name '*.log' -o -name '*.txt' \\) -size -1024k 2>/dev/null | head -n 400 | while read -r f; do cp -f \"$f\" '$DEST/logs/' 2>/dev/null || true; done || true"
done

# ---------- pip packages ----------
echo -e "\n== PYTHON PACKAGES ==" >> "$OUT/REPORT.txt"
runsh "python -m pip list --format=freeze | head -n 4000"

# ---------- Build a manifest.json ----------
python - <<PY
import json, time, pathlib, subprocess, os
out = pathlib.Path(r"$OUT")
roots = out.joinpath("ROOTS.txt").read_text().splitlines()

def sh(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT).strip()
    except Exception as e:
        return str(e)

manifest = {
  "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
  "termux": True,
  "uname": sh("uname -a"),
  "roots": roots,
  "disk": sh("df -h"),
  "listening_ports": sh("ss -ltnp 2>/dev/null || true"),
}
(out/"manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
print("✅ manifest.json written")
PY

# ---------- Zip result ----------
ZIP="$HOME/Sovereign_Collector_Report_$TS.zip"
cd "$(dirname "$OUT")"
zip -qr "$ZIP" "$(basename "$OUT")"

echo "✅ Done."
echo "📦 Report ZIP: $ZIP"
echo "ℹ️ ارفعه هنا وسأعطيك خطة ترقيات Zero-Break دقيقة + Patch جاهز."
