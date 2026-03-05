#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BIN="${1:-$HOME/seboot_artifacts/seboot.platform.final.bin}"
OUTDIR="$HOME/seboot_artifacts"
REPORT="$OUTDIR/seboot_summary_$(date +%Y%m%d_%H%M%S).txt"

mkdir -p "$OUTDIR"

say(){ printf "%s\n" "$*"; }
err(){ printf "[ERR] %s\n" "$*" >&2; }
ok(){  printf "[OK] %s\n" "$*"; }

[ -f "$BIN" ] || { err "Binary not found: $BIN"; exit 2; }

PERMS="$(ls -l "$BIN" | awk '{print $1, $3, $4}')"
SIZE_H="$(ls -lh "$BIN" | awk '{print $5}')"
SHA="$(sha256sum "$BIN" | awk '{print $1}')"
FTYPE="$(file "$BIN" 2>/dev/null || true)"

HELP_STATUS="N/A"
HELP_OUT="(skipped)"

if [ -x "$BIN" ]; then
  set +e
  HELP_OUT="$("$BIN" --help 2>&1 | sed -n '1,80p')"
  HELP_STATUS="$?"
  set -e
else
  HELP_STATUS="not executable"
fi

# Console summary (one-liner + block)
say "SEBOOT_SUMMARY | bin=$BIN | size=$SIZE_H | sha256=$SHA | help_rc=$HELP_STATUS"
say
say "================ SEBOOT SUMMARY ================"
say "Binary path   : $BIN"
say "Permissions   : $PERMS"
say "Binary size   : $SIZE_H"
say "SHA256        : $SHA"
say "File type     : $FTYPE"
say "Help exitcode : $HELP_STATUS"
say "--------------- --help (first 80 lines) --------"
say "$HELP_OUT"
say "================================================"

# Save report
{
  echo "================ SEBOOT SUMMARY ================"
  echo "Timestamp     : $(date -Iseconds)"
  echo "Binary path   : $BIN"
  echo "Permissions   : $PERMS"
  echo "Binary size   : $SIZE_H"
  echo "SHA256        : $SHA"
  echo "File type     : $FTYPE"
  echo "Help exitcode : $HELP_STATUS"
  echo "--------------- --help (first 80 lines) --------"
  echo "$HELP_OUT"
  echo "================================================"
} > "$REPORT"

ok "Saved report: $REPORT"
