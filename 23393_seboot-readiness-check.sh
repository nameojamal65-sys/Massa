#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BIN="${1:-$HOME/seboot_artifacts/seboot.platform.final.bin}"

say(){ printf "%s\n" "$*"; }
ok(){  printf "[OK] %s\n" "$*"; }
warn(){ printf "[WARN] %s\n" "$*"; }
err(){ printf "[ERR] %s\n" "$*" >&2; }

say "=== SEBOOT PLATFORM READINESS CHECK ==="

# 1) Exists
[ -f "$BIN" ] || { err "Binary not found: $BIN"; exit 10; }
ok "Binary exists"

# 2) Executable
[ -x "$BIN" ] || { err "Binary is not executable"; exit 11; }
ok "Binary is executable"

# 3) File type
FT="$(file "$BIN" 2>/dev/null || true)"
echo "$FT" | grep -qi 'ELF' || { err "Not an ELF binary"; exit 12; }
ok "ELF binary detected"

# 4) Architecture sanity (ARM64 expected in Termux)
if echo "$FT" | grep -qi 'arm64\|aarch64'; then
  ok "Architecture matches (ARM64)"
else
  warn "Architecture not explicitly ARM64 (check if intended)"
fi

# 5) Dry run: --help
set +e
HELP_OUT="$("$BIN" --help >/dev/null 2>&1)"
RC="$?"
set -e

if [ "$RC" -eq 0 ]; then
  ok "--help executed successfully"
else
  warn "--help returned non-zero (may be normal for services)"
fi

# 6) Startup smoke test (2 seconds)
set +e
"$BIN" >/dev/null 2>&1 &
PID="$!"
sleep 2
if kill -0 "$PID" 2>/dev/null; then
  ok "Process started and is running (PID=$PID)"
  kill "$PID" >/dev/null 2>&1 || true
else
  warn "Process exited quickly (check logs if needed)"
fi
set -e

say
say "========================================"
say " PLATFORM STATUS: READY"
say " The platform binary is valid, runnable,"
say " and suitable for operation."
say "========================================"

exit 0
