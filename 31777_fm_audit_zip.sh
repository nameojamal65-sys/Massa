#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[!] Missing: $1 (pkg install $1)"; exit 2; }; }

need unzip
need awk
need sed
need grep
need sort
need head
need tail
need wc
need date

ZIP="${1:-}"
if [ -z "$ZIP" ] || [ ! -f "$ZIP" ]; then
  echo "Usage: $0 /path/to/bundle.zip"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"

hr(){ printf "%s\n" "------------------------------------------------------------"; }
say(){ printf "\n\033[1m%s\033[0m\n" "$*"; }

fmt_bytes() {
  awk -v b="$1" 'function human(x){
    s="B KB MB GB TB"; split(s,a," "); i=1;
    while (x>=1024 && i<5){x/=1024; i++}
    return sprintf("%.2f %s", x, a[i])
  } BEGIN{print human(b)}'
}

# 1) Integrity
say "ZIP Integrity"
hr
if unzip -tq "$ZIP" >/dev/null 2>&1; then
  echo "[OK] ZIP integrity OK"
else
  echo "[X] ZIP integrity FAILED"
  exit 3
fi

# 2) Basic metrics from zip listing
say "Basic Metrics"
hr
archive_bytes="$(wc -c < "$ZIP" | awk '{print $1}')"

# unzip -l: last line contains totals: "  <files> <bytes> ..."
totals="$(unzip -l "$ZIP" | tail -n 1)"
file_count="$(echo "$totals" | awk '{print $2}')"
uncompressed_bytes="$(echo "$totals" | awk '{print $1}')"

echo "timestamp: $STAMP"
echo "zip: $ZIP"
echo "files: $file_count"
echo "size_archive:      $(fmt_bytes "$archive_bytes")"
echo "size_uncompressed: $(fmt_bytes "$uncompressed_bytes")"

# 3) File list (paths only)
# unzip -Z -1 gives one path per line
paths="$(unzip -Z -1 "$ZIP" 2>/dev/null || true)"

# helper: check any match (case-insensitive)
has_any() {
  echo "$paths" | grep -Eiq "$1"
}

count_re() {
  echo "$paths" | grep -Ei "$1" | wc -l | awk '{print $1}'
}

say "Structure Detection (ZIP-native heuristics)"
hr

# UI signals
has_webui=0
if has_any '(^|/)(webui|frontend|ui|dashboard)/' || has_any '(^|/)dist/.*index\.html$' || has_any 'index\.html$'; then
  has_webui=1
fi

# Core / binaries signals
has_bin=0
if has_any '(^|/)bin/' ; then has_bin=1; fi

# Backend signals (source or deployment)
has_backend=0
if has_any '(^|/)(server|api|backend|internal)/' \
   || has_any '\.jar$|\.war$|go\.mod$|requirements\.txt$|pyproject\.toml$|package\.json$|\.csproj$' \
   || has_any 'Dockerfile|docker-compose'; then
  has_backend=1
fi

# Config/docs/runner/deploy
has_configs=0
if has_any '\.ya?ml$|\.json$|\.toml$|(^|/)\.env($|\.|/)|config/'; then has_configs=1; fi

has_docs=0
if has_any '(^|/)(README|readme)\b|\.md$|(^|/)docs/'; then has_docs=1; fi

has_runner=0
if has_any '(^|/)(run|start)[^/]*\.sh$|run_core\.sh$'; then has_runner=1; fi

has_docker=0
if has_any 'Dockerfile' || has_any 'docker-compose[^/]*\.ya?ml$'; then has_docker=1; fi

has_k8s=0
if has_any '(^|/)(k8s|manifests)/' || has_any '(deployment|service|ingress)[^/]*\.ya?ml$'; then has_k8s=1; fi

echo "has_webui:   $has_webui"
echo "has_bin:     $has_bin"
echo "has_backend: $has_backend"
echo "has_configs: $has_configs"
echo "has_docs:    $has_docs"
echo "has_runner:  $has_runner"
echo "has_docker:  $has_docker"
echo "has_k8s:     $has_k8s"

say "Counts (extensions & key files)"
hr
echo "yaml:   $(count_re '\.ya?ml$')"
echo "json:   $(count_re '\.json$')"
echo "env:    $(count_re '(^|/)\.env($|\.|/)')"
echo "toml:   $(count_re '\.toml$')"
echo "md:     $(count_re '\.md$')"
echo "sh:     $(count_re '\.sh$')"
echo "html:   $(count_re '\.html$')"
echo "js/ts:  $(count_re '\.(js|ts)$')"
echo "go.mod: $(count_re 'go\.mod$')"
echo "docker: $(count_re 'Dockerfile|docker-compose[^/]*\.ya?ml$')"

say "What it produces (heuristic classification)"
hr
classification="unknown"
if [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 1 ] && [ "$has_webui" -eq 1 ]; then
  classification="full-stack platform (core + backend + web UI)"
elif [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 1 ]; then
  classification="service/backend platform (core + backend, UI not detected)"
elif [ "$has_webui" -eq 1 ] && [ "$has_backend" -eq 0 ]; then
  classification="web UI bundle (frontend only)"
elif [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 0 ]; then
  classification="core/binary package (no clear backend detected)"
else
  classification="bundle of configs/meta/scripts (no obvious runtime)"
fi
echo "classification: $classification"

say "Google / GCP deployability (heuristic)"
hr
gcp="unknown"
if [ "$has_k8s" -eq 1 ]; then
  gcp="high: k8s manifests detected (GKE candidate) — needs images/secrets"
elif [ "$has_docker" -eq 1 ]; then
  gcp="medium-high: Docker/Compose detected (Cloud Run / GCE / GKE) — needs build+push"
elif [ "$has_backend" -eq 1 ] || [ "$has_bin" -eq 1 ]; then
  gcp="medium: runnable on Compute Engine VM (entrypoint+deps needed); containerization recommended"
else
  gcp="low: no runnable artifacts detected"
fi
echo "gcp_readiness: $gcp"

say "Cohesion & Completeness (heuristics)"
hr
echo "runnable_guess: $(
  if [ "$has_docker" -eq 1 ] || [ "$has_runner" -eq 1 ] || [ "$has_bin" -eq 1 ]; then echo likely; else echo unlikely; fi
)"

warn=0
if [ "$has_runner" -eq 0 ]; then echo "- warning: no runner/start script"; warn=1; fi
if [ "$has_configs" -eq 0 ]; then echo "- warning: no configs detected"; warn=1; fi
if [ "$has_docs" -eq 0 ]; then echo "- warning: no README/docs detected"; warn=1; fi
if [ "$warn" -eq 0 ]; then echo "warnings: none"; fi

say "Largest files inside ZIP (top 15 by uncompressed size)"
hr
# unzip -l output: size date time name
unzip -l "$ZIP" | awk 'NR>3 {print $1"\t"$4}' | grep -E '^[0-9]+' \
  | sort -n | tail -n 15 | awk 'BEGIN{MB=1024*1024}{printf "%8.1f MB\t%s\n",$1/MB,$2}'

say "JSON summary"
hr
json_escape(){ echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
zip_esc="$(json_escape "$ZIP")"
cls_esc="$(json_escape "$classification")"
gcp_esc="$(json_escape "$gcp")"
printf '{\n'
printf '  "timestamp":"%s",\n' "$STAMP"
printf '  "zip":"%s",\n' "$zip_esc"
printf '  "files":%s,\n' "$file_count"
printf '  "size_archive":"%s",\n' "$(fmt_bytes "$archive_bytes")"
printf '  "size_uncompressed":"%s",\n' "$(fmt_bytes "$uncompressed_bytes")"
printf '  "has":{"webui":%s,"bin":%s,"backend":%s,"configs":%s,"docs":%s,"runner":%s,"docker":%s,"k8s":%s},\n' \
  "$has_webui" "$has_bin" "$has_backend" "$has_configs" "$has_docs" "$has_runner" "$has_docker" "$has_k8s"
printf '  "classification":"%s",\n' "$cls_esc"
printf '  "gcp_readiness":"%s"\n' "$gcp_esc"
printf '}\n'

echo ""
echo "[OK] Audit complete."
