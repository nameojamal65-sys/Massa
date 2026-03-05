#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ==========================================================
# ForgeMind Bundle Auditor (zip or directory)
# Outputs: human report + JSON summary
# ==========================================================

need() { command -v "$1" >/dev/null 2>&1 || { echo "[!] Missing: $1 (install: pkg install $1)"; exit 2; }; }

need awk
need sed
need grep
need find
need du
need wc
need sort
need head
need tail
need date
need mktemp

# Optional tools
have() { command -v "$1" >/dev/null 2>&1; }
if have unzip; then :; else echo "[!] Missing unzip (install: pkg install unzip)"; exit 2; fi
if have file; then :; else echo "[!] 'file' not found (install: pkg install file)"; fi
if have sha256sum; then :; else echo "[!] sha256sum not found (install: pkg install coreutils)"; fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage:"
  echo "  $0 <bundle.zip | directory>"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
TMPDIR=""
ROOT=""

cleanup() {
  [ -n "${TMPDIR:-}" ] && rm -rf "$TMPDIR" || true
}
trap cleanup EXIT

is_zip=0
if [ -f "$TARGET" ] && echo "$TARGET" | grep -qiE '\.zip$'; then
  is_zip=1
fi

# ---------- Prepare root ----------
if [ "$is_zip" -eq 1 ]; then
  TMPDIR="$(mktemp -d)"
  ROOT="$TMPDIR/root"
  mkdir -p "$ROOT"

  echo "[*] Checking ZIP integrity..."
  if ! unzip -tq "$TARGET" >/dev/null 2>&1; then
    echo "[X] ZIP integrity FAILED (corrupt or incomplete)."
    echo "    Try re-zip or re-upload."
    exit 3
  fi
  echo "[OK] ZIP integrity OK."

  # Extract (quiet)
  unzip -qq "$TARGET" -d "$ROOT"
else
  if [ ! -d "$TARGET" ]; then
    echo "[X] Not a zip and not a directory: $TARGET"
    exit 1
  fi
  ROOT="$TARGET"
fi

# ---------- Helpers ----------
hr() { printf "%s\n" "------------------------------------------------------------"; }
say() { printf "\n\033[1m%s\033[0m\n" "$*"; }
exists_any() { # pattern list
  local p
  for p in "$@"; do
    if find "$ROOT" -path "$p" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done
  return 1
}
count_matches() {
  local re="$1"
  find "$ROOT" -type f 2>/dev/null | grep -Ei "$re" | wc -l | awk '{print $1}'
}
top_by_size() {
  local where="$1"
  local n="${2:-15}"
  find "$where" -type f -printf "%s\t%p\n" 2>/dev/null | sort -n | tail -n "$n" \
    | awk 'BEGIN{MB=1024*1024}{printf "%8.1f MB\t%s\n",$1/MB,$2}'
}

# ---------- Basic metrics ----------
say "Bundle Audit Report"
hr
echo "timestamp: $STAMP"
echo "input: $TARGET"
echo "mode: $([ "$is_zip" -eq 1 ] && echo zip || echo directory)"
echo "root: $ROOT"

archive_size_bytes=0
if [ "$is_zip" -eq 1 ]; then
  archive_size_bytes="$(wc -c < "$TARGET" | awk '{print $1}')"
fi

total_files="$(find "$ROOT" -type f 2>/dev/null | wc -l | awk '{print $1}')"
total_dirs="$(find "$ROOT" -type d 2>/dev/null | wc -l | awk '{print $1}')"
total_size_bytes="$(du -sb "$ROOT" 2>/dev/null | awk '{print $1}' || true)"
if [ -z "${total_size_bytes:-}" ]; then
  # fallback if du -b not supported
  total_size_bytes="$(du -sk "$ROOT" 2>/dev/null | awk '{print $1*1024}')"
fi

fmt_bytes() {
  awk -v b="$1" 'function human(x){
    s="B KB MB GB TB"; split(s,a," "); i=1;
    while (x>=1024 && i<5){x/=1024; i++}
    return sprintf("%.2f %s", x, a[i])
  } BEGIN{print human(b)}'
}

echo "files: $total_files"
echo "dirs:  $total_dirs"
echo "size_uncompressed: $(fmt_bytes "$total_size_bytes")"
if [ "$is_zip" -eq 1 ]; then
  echo "size_archive:      $(fmt_bytes "$archive_size_bytes")"
fi

# ---------- Structure detection ----------
say "Structure Detection (heuristics)"
hr

has_bin=0
has_webui=0
has_backend=0
has_configs=0
has_docs=0
has_runner=0
has_docker=0
has_k8s=0

# Common layout signals
if [ -d "$ROOT/bin" ] || exists_any "*/bin/*"; then has_bin=1; fi
if [ -d "$ROOT/webui" ] || exists_any "*/webui/*" "*/frontend/*" "*/dashboard/*" "*/dist/*/index.html" "*/build/*/index.html" "*index.html"; then has_webui=1; fi
if [ -d "$ROOT/config" ] || exists_any "*/config/*" "*/*.env" "*/*.yaml" "*/*.yml" "*/*.toml" "*/*.json"; then has_configs=1; fi
if exists_any "*/README*" "*/*.md" "*/docs/*"; then has_docs=1; fi
if exists_any "*/run*.sh" "*/*run*.sh" "*/start*.sh" "*/*start*.sh"; then has_runner=1; fi
if exists_any "*/Dockerfile*" "*/docker-compose*.yml" "*/docker-compose*.yaml"; then has_docker=1; fi
if exists_any "*/k8s/*" "*/manifests/*" "*/*deployment*.yml" "*/*deployment*.yaml" "*/*service*.yml" "*/*ingress*.yml"; then has_k8s=1; fi

# Backend / server hints
backend_hits=$(( \
  $(count_matches '/server/|/api/|/backend/|docker-compose|Dockerfile|\.jar$|\.war$|\.py$|\.js$|\.ts$|go\.mod$|\.csproj$|\.php$') \
))
if [ "$backend_hits" -gt 0 ]; then has_backend=1; fi

echo "has_bin:      $has_bin"
echo "has_webui:    $has_webui"
echo "has_backend:  $has_backend"
echo "has_configs:  $has_configs"
echo "has_docs:     $has_docs"
echo "has_runner:   $has_runner"
echo "has_docker:   $has_docker"
echo "has_k8s:      $has_k8s"

# ---------- Deep checks ----------
say "Deep Checks"
hr

# Executables in bin (if any)
exe_count=0
if [ "$has_bin" -eq 1 ]; then
  if have file; then
    exe_count="$(find "$ROOT" -type f -path "*/bin/*" 2>/dev/null | wc -l | awk '{print $1}')"
    echo "bin_files: $exe_count"
    echo "bin_samples:"
    find "$ROOT" -type f -path "*/bin/*" 2>/dev/null | head -n 8 | while read -r f; do
      echo "  - $(basename "$f"): $(file -b "$f" 2>/dev/null || echo unknown)"
    done
  else
    exe_count="$(find "$ROOT" -type f -path "*/bin/*" -perm -u+x 2>/dev/null | wc -l | awk '{print $1}')"
    echo "bin_executables(+x): $exe_count"
  fi
else
  echo "bin: not detected"
fi

# WebUI markers
if [ "$has_webui" -eq 1 ]; then
  ui_index="$(find "$ROOT" -type f -iname "index.html" 2>/dev/null | head -n 1 || true)"
  pkg_json_count="$(find "$ROOT" -type f -iname "package.json" 2>/dev/null | wc -l | awk '{print $1}')"
  echo "webui_index_example: ${ui_index:-none}"
  echo "webui_package_json_count: $pkg_json_count"
else
  echo "webui: not detected"
fi

# Backend markers
if [ "$has_backend" -eq 1 ]; then
  go_mod="$(find "$ROOT" -type f -iname "go.mod" 2>/dev/null | head -n 1 || true)"
  compose="$(find "$ROOT" -type f -iname "docker-compose*.yml" -o -iname "docker-compose*.yaml" 2>/dev/null | head -n 1 || true)"
  dockerfile="$(find "$ROOT" -type f -iname "Dockerfile*" 2>/dev/null | head -n 1 || true)"
  echo "backend_go_mod: ${go_mod:-none}"
  echo "docker_compose_example: ${compose:-none}"
  echo "dockerfile_example: ${dockerfile:-none}"
else
  echo "backend: not detected"
fi

# Config sanity: count configs
yaml_count="$(count_matches '\.ya?ml$')"
json_count="$(count_matches '\.json$')"
env_count="$(count_matches '(^|/)\.env(\.|$)|\.env$')"
toml_count="$(count_matches '\.toml$')"
echo "config_counts: yaml=$yaml_count json=$json_count env=$env_count toml=$toml_count"

# Manifest + hashes
manifest_path="$(find "$ROOT" -type f -path "*/meta/manifest.txt" 2>/dev/null | head -n 1 || true)"
sha_path="$(find "$ROOT" -type f -path "*/meta/sha256sums.txt" 2>/dev/null | head -n 1 || true)"
echo "manifest: ${manifest_path:-none}"
echo "sha256sums: ${sha_path:-none}"

sha_ok="unknown"
if [ -n "${sha_path:-}" ] && [ -f "$sha_path" ] && have sha256sum; then
  # Verify hashes, best effort (ignore missing meta/*)
  say "Hash Verification (best effort)"
  hr
  # run inside directory of sha file
  sha_dir="$(cd "$(dirname "$sha_path")/.." && pwd)"
  # shellcheck disable=SC2164
  cd "$sha_dir"
  if sha256sum -c "meta/sha256sums.txt" >/dev/null 2>&1; then
    echo "[OK] sha256 verification: PASS"
    sha_ok="pass"
  else
    echo "[!] sha256 verification: FAIL (some files changed/missing)"
    sha_ok="fail"
  fi
fi

# ---------- "What does it produce?" heuristic ----------
say "What this bundle likely is (heuristics)"
hr
product="unknown"

if [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 1 ] && [ "$has_webui" -eq 1 ]; then
  product="full-stack platform (core + backend + web UI)"
elif [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 1 ]; then
  product="service/backend platform (core + backend, UI not detected)"
elif [ "$has_webui" -eq 1 ] && [ "$has_backend" -eq 0 ]; then
  product="frontend/web UI bundle (no backend detected)"
elif [ "$has_bin" -eq 1 ] && [ "$has_backend" -eq 0 ]; then
  product="core/binary package (no clear backend detected)"
fi
echo "classification: $product"

# ---------- "Can we run it on Google?" heuristic ----------
say "Google/GCP deployability (heuristics)"
hr
gcp="unknown"

# Heuristic ladder
if [ "$has_k8s" -eq 1 ]; then
  gcp="high: k8s manifests detected (GKE candidate) — still needs images/secrets"
elif [ "$has_docker" -eq 1 ]; then
  gcp="medium-high: Docker/Docker-Compose detected (Cloud Run/GCE/GKE candidate) — needs build/push steps"
elif [ "$has_backend" -eq 1 ] || [ "$has_bin" -eq 1 ]; then
  gcp="medium: runnable on Compute Engine/VM if entrypoint+deps are clear; containerization recommended"
else
  gcp="low: no obvious runtime artifacts"
fi
echo "gcp_readiness: $gcp"

# ---------- Architectural cohesion / completeness (heuristics) ----------
say "Cohesion & Completeness (heuristics)"
hr

# Signals
missing=()
warn=()

if [ "$has_runner" -eq 0 ]; then warn+=("no runner/start script detected (run_core.sh/run.sh/start.sh)") ; fi
if [ "$has_configs" -eq 0 ]; then warn+=("no configs detected (config/*.yml/.env/*.json)") ; fi
if [ "$has_docs" -eq 0 ]; then warn+=("no docs/README detected") ; fi
if [ "$has_backend" -eq 1 ] && [ "$has_docker" -eq 0 ] && [ "$has_bin" -eq 0 ]; then warn+=("backend hints exist but no Dockerfile/compose and no binaries detected — may be source-only") ; fi

# Minimal runnable expectation
runnable_guess="no"
if [ "$has_bin" -eq 1 ] || [ "$has_docker" -eq 1 ]; then runnable_guess="likely"; fi
if [ "$has_runner" -eq 1 ] || [ "$has_docker" -eq 1 ]; then runnable_guess="more-likely"; fi

echo "runnable_guess: $runnable_guess"
echo "sha256_verification: $sha_ok"

if [ "${#warn[@]}" -gt 0 ]; then
  echo "warnings:"
  for w in "${warn[@]}"; do echo "  - $w"; done
else
  echo "warnings: none"
fi

# Biggest files
say "Largest files (top 15)"
hr
top_by_size "$ROOT" 15 || true

# ---------- JSON summary ----------
say "JSON summary (copy/paste-friendly)"
hr
json_escape() { echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

arch_size="$(fmt_bytes "$archive_size_bytes" 2>/dev/null || echo "")"
uncomp_size="$(fmt_bytes "$total_size_bytes")"
input_esc="$(json_escape "$TARGET")"
root_esc="$(json_escape "$ROOT")"
product_esc="$(json_escape "$product")"
gcp_esc="$(json_escape "$gcp")"

printf '{\n'
printf '  "timestamp": "%s",\n' "$STAMP"
printf '  "input": "%s",\n' "$input_esc"
printf '  "mode": "%s",\n' "$([ "$is_zip" -eq 1 ] && echo zip || echo directory)"
printf '  "root": "%s",\n' "$root_esc"
printf '  "files": %s,\n' "$total_files"
printf '  "dirs": %s,\n' "$total_dirs"
printf '  "size_uncompressed": "%s",\n' "$uncomp_size"
if [ "$is_zip" -eq 1 ]; then
  printf '  "size_archive": "%s",\n' "$(fmt_bytes "$archive_size_bytes")"
fi
printf '  "has": {\n'
printf '    "bin": %s,\n' "$has_bin"
printf '    "webui": %s,\n' "$has_webui"
printf '    "backend": %s,\n' "$has_backend"
printf '    "configs": %s,\n' "$has_configs"
printf '    "docs": %s,\n' "$has_docs"
printf '    "runner": %s,\n' "$has_runner"
printf '    "docker": %s,\n' "$has_docker"
printf '    "k8s": %s\n' "$has_k8s"
printf '  },\n'
printf '  "classification": "%s",\n' "$product_esc"
printf '  "gcp_readiness": "%s",\n' "$gcp_esc"
printf '  "runnable_guess": "%s",\n' "$runnable_guess"
printf '  "sha256_verification": "%s"\n' "$sha_ok"
printf '}\n'

echo ""
echo "[OK] Audit complete."
