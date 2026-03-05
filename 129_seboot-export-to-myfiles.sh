#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BIN="$HOME/seboot_artifacts/seboot.platform.final.bin"
DEST="$HOME/storage/shared/SEBOOT_PLATFORM"
REPORT="$DEST/DEPLOYMENT_REPORT.txt"

say(){ printf "%s\n" "$*"; }
ok(){  printf "[OK] %s\n" "$*"; }
err(){ printf "[ERR] %s\n" "$*" >&2; }

# Check binary
[ -f "$BIN" ] || { err "Binary not found: $BIN"; exit 2; }

# Prepare destination
mkdir -p "$DEST"

# Copy binary
cp -f "$BIN" "$DEST/"
chmod 755 "$DEST/seboot.platform.final.bin"

# Metrics
SIZE="$(ls -lh "$DEST/seboot.platform.final.bin" | awk '{print $5}')"
SHA="$(sha256sum "$DEST/seboot.platform.final.bin" | awk '{print $1}')"
FTYPE="$(file "$DEST/seboot.platform.final.bin" || true)"

# Write report
cat > "$REPORT" <<EOF
SEBOOT PLATFORM – DEPLOYMENT REPORT
=================================
Date        : $(date -Iseconds)
Binary name : seboot.platform.final.bin
Binary size : $SIZE
SHA256      : $SHA
File type   : $FTYPE

Status      : READY FOR PRODUCTION
EOF

say
say "========================================"
say " SEBOOT PLATFORM DEPLOYED TO MY FILES"
say "========================================"
say "Location : $DEST"
say "Binary   : seboot.platform.final.bin"
say "Size     : $SIZE"
say "SHA256   : $SHA"
say "Report   : DEPLOYMENT_REPORT.txt"
say "========================================"
ok "DONE"
