#!/bin/bash
# ========================================
# 👑 PAI6 — Set Permissions Script
# ========================================

echo "⚙️  Setting permissions for all builder files..."

FILES=(
  "$HOME/server.js"
  "$HOME/dashboard.py"
  "$HOME/build_all.sh"
)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    chmod +x "$f"
    echo "✅ Permissions set for $f"
  else
    echo "❌ File not found: $f"
  fi
done

echo "🎯 All permissions set successfully!"
