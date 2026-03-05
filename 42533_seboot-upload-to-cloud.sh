#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REMOTE="mycloud:SEBOOT_PLATFORM"
LOCAL="$HOME/storage/shared/SEBOOT_PLATFORM"

say(){ printf "%s\n" "$*"; }
ok(){ printf "[OK] %s\n" "$*"; }
err(){ printf "[ERR] %s\n" "$*" >&2; }

[ -d "$LOCAL" ] || { err "Local folder not found: $LOCAL"; exit 2; }

say "[+] Uploading to cloud: $REMOTE"
rclone copy "$LOCAL" "$REMOTE" --progress

say
say "========================================"
say " UPLOAD COMPLETED"
say " Cloud path : $REMOTE"
say "========================================"
ok "DONE"
