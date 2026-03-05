#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
c_blue="\033[1;34m"; c_yel="\033[1;33m"; c_red="\033[1;31m"; c_off="\033[0m"
log(){ printf "${c_blue}[repair]${c_off} %s\n" "$*"; }
warn(){ printf "${c_yel}[repair]${c_off} %s\n" "$*"; }
die(){ printf "${c_red}[repair]${c_off} %s\n" "$*"; exit 1; }

ROOT="$(pwd)"
[[ -f "$ROOT/go.mod" ]] || die "شغّلني من جذر المشروع (مكان go.mod)."

log "ROOT=$ROOT"

log "deps..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y curl unzip coreutils findutils grep sed gawk git ca-certificates golang clang make pkg-config >/dev/null 2>&1 || true
command -v go >/dev/null || die "Go غير موجود"
command -v curl >/dev/null || die "curl غير موجود"

log "$(go version)"

log "go:embed scan + auto placeholders..."
mapfile -t EMBED_GOS < <(grep -RIn --include='*.go' -E '^[[:space:]]*//go:embed[[:space:]]+' . 2>/dev/null | cut -d: -f1 | sort -u || true)

mkf(){ mkdir -p "$(dirname "$1")"; [[ -f "$1" ]] || { printf "%s\n" "$2" >"$1"; warn "created: $1"; }; }
mkd(){ mkdir -p "$1"; [[ -f "$1/placeholder.txt" ]] || { echo "placeholder" >"$1/placeholder.txt"; warn "created: $1/placeholder.txt"; }; }

for gf in "${EMBED_GOS[@]}"; do
  [[ -f "$gf" ]] || continue
  gdir="$(dirname "$gf")"
  while IFS= read -r line; do
    pat="${line#*//go:embed}"
    pat="$(echo "$pat" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [[ -n "$pat" ]] || continue
    for token in $pat; do
      if echo "$token" | grep -qE '[\*\?\[]'; then
        base="${token%%[*?[]*}"; base="${base%/}"
        [[ -n "$base" ]] && mkd "$gdir/$base" || warn "wildcard embed (skip base): $token in $gf"
      else
        case "$token" in
          *.html) mkf "$gdir/$token" '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ForgeMind</title></head><body><h1>ForgeMind</h1><p>Embedded UI placeholder.</p></body></html>' ;;
          *.css)  mkf "$gdir/$token" '/* embedded placeholder */' ;;
          *.js)   mkf "$gdir/$token" '// embedded placeholder' ;;
          *.json) mkf "$gdir/$token" '{}' ;;
          *)      mkf "$gdir/$token" 'placeholder' ;;
        esac
      fi
    done
  done < <(grep -E '^[[:space:]]*//go:embed[[:space:]]+' "$gf" || true)
done

log "detect main..."
MAIN_PKGS="$(go list -f '{{if eq .Name "main"}}{{.ImportPath}}{{"\n"}}{{end}}' ./... 2>/dev/null | sed '/^$/d' || true)"
[[ -n "$MAIN_PKGS" ]] || die "لا يوجد main package. (قد يكون المشروع يحتاج build tags)."

MAIN="$(printf "%s\n" "$MAIN_PKGS" | grep -E '/cmd/' | head -n1 || true)"
[[ -n "$MAIN" ]] || MAIN="$(printf "%s\n" "$MAIN_PKGS" | head -n1)"
log "MAIN=$MAIN"

mkdir -p "$ROOT/bin"
OUT="$ROOT/bin/forgemind"
log "build -> $OUT"
export CGO_ENABLED=1
go build -trimpath -o "$OUT" "$MAIN"
log "build ok"

mkdir -p "$ROOT/scripts/termux"
cat > "$ROOT/scripts/termux/run.sh" <<'RUN'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/bin/forgemind"
PORT="${PORT:-8080}"
ADDR="${ADDR:-127.0.0.1:${PORT}}"
echo "[run] $BIN"
echo "[run] health: curl -s http://$ADDR/health"
exec "$BIN"
RUN
chmod +x "$ROOT/scripts/termux/run.sh" || true

log "done. next: bash scripts/termux/run.sh"
