#!/data/data/com.termux/files/usr/bin/bash

echo "🔐 Applying Sovereign Execution Permissions..."

TARGET="$HOME/sovereign_ultra.sh"

if [ ! -f "$TARGET" ]; then
  echo "❌ Script not found: $TARGET"
  exit 1
fi

chmod +x "$TARGET"
chmod 700 "$TARGET"
sed -i 's/\r$//' "$TARGET"

echo "✅ Permissions applied"
echo "🚀 Launching Sovereign Ultra Scanner..."
sleep 1
"$TARGET"
