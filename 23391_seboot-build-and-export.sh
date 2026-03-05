#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

say(){ printf "%s\n" "$*"; }
err(){ printf "[ERR] %s\n" "$*" >&2; }
ok(){  printf "[OK] %s\n" "$*"; }

START="${1:-$PWD}"

# ابحث عن مجلد يحتوي go.mod و cmd/seboot
find_root() {
  local base="$1"
  # 1) لو أنت بالفعل داخل مشروع
  if [ -f "$base/go.mod" ] && [ -d "$base/cmd/seboot" ]; then
    printf "%s\n" "$base"; return 0
  fi

  # 2) بحث ضمن أهم مجلداتك المحتملة (workspace/result)
  local candidates=(
    "$HOME/sovereign_build_workspace"
    "$HOME/sovereign_build_out"
    "$HOME/_forgemind_src"
    "$HOME"
  )

  local d
  for d in "${candidates[@]}"; do
    [ -d "$d" ] || continue
    # نبحث بسرعة عن cmd/seboot ثم نتحقق من وجود go.mod بجواره
    while IFS= read -r p; do
      local root
      root="$(dirname "$(dirname "$p")")"  # .../cmd/seboot -> root
      if [ -f "$root/go.mod" ] && [ -d "$root/cmd/seboot" ]; then
        printf "%s\n" "$root"; return 0
      fi
    done < <(find "$d" -type d -path "*/cmd/seboot" 2>/dev/null | head -n 20)
  done

  return 1
}

ROOT="$(find_root "$START" || true)"
if [ -z "${ROOT:-}" ]; then
  err "لم أستطع العثور على مشروع seboot (go.mod + cmd/seboot)."
  err "جرّب تشغيل السكربت مع مسار workspace:"
  err "  ./seboot-build-and-export.sh ~/sovereign_build_workspace"
  exit 2
fi

ok "Project root: $ROOT"

OUTDIR="$ROOT/dist"
BIN="$OUTDIR/seboot.platform.final.bin"
USER_FILES="$HOME/seboot_artifacts"

mkdir -p "$OUTDIR" "$USER_FILES"

say "[+] Building (hardened) ..."
( cd "$ROOT" && go build -ldflags="-s -w" -o "$BIN" ./cmd/seboot )

ok "Built: $BIN"

say "[+] Exporting to: $USER_FILES"
cp -f "$BIN" "$USER_FILES/"

# Metrics
say "[+] Computing metrics ..."
FILE_COUNT="$(find "$ROOT" -type f \
  ! -path "$ROOT/.git/*" \
  ! -path "$ROOT/dist/*" \
  ! -path "$ROOT/vendor/*" \
  2>/dev/null | wc -l | tr -d ' ')"

SRC_SIZE="$(du -sh "$ROOT" | awk '{print $1}')"
BIN_SIZE="$(du -h "$USER_FILES/seboot.platform.final.bin" | awk '{print $1}')"
BIN_SHA="$(sha256sum "$USER_FILES/seboot.platform.final.bin" | awk '{print $1}')"
BIN_FILE="$(file "$USER_FILES/seboot.platform.final.bin" || true)"

say
say "========================================"
say " SEBOOT PLATFORM — FINAL REPORT"
say "========================================"
say "Project root       : $ROOT"
say "Binary path        : $USER_FILES/seboot.platform.final.bin"
say "Binary size        : $BIN_SIZE"
say "Binary SHA256      : $BIN_SHA"
say "Binary file info   : $BIN_FILE"
say "----------------------------------------"
say "Source file count  : $FILE_COUNT"
say "Source tree size   : $SRC_SIZE"
say "========================================"
ok "DONE"
