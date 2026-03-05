#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
DATA="${DATA:-./data}"
KEYS="$DATA/registry/keys"
ACTIVE="$KEYS/active_key.json"
mkdir -p "$KEYS"
# Make a new key by deleting active key so server will regenerate on next register.
if [[ -f "$ACTIVE" ]]; then
  mv "$ACTIVE" "$ACTIVE.bak.$(date +%s)"
fi
echo "[rotate] active key cleared; next register will generate a new key"
