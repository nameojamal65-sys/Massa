#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "🔧 Updating packages..."
pkg update -y >/dev/null

echo "📦 Installing rclone..."
pkg install rclone -y >/dev/null

CONFIG_DIR="$HOME/.config/rclone"
CONFIG_FILE="$CONFIG_DIR/rclone.conf"

echo "📁 Preparing rclone config directory..."
mkdir -p "$CONFIG_DIR"

echo "🧹 Removing old gdrive config if exists..."
if rclone listremotes | grep -q "^gdrive:$"; then
  rclone config delete gdrive >/dev/null
fi

echo "☁️ Creating Google Drive remote (gdrive)..."
rclone config create gdrive drive scope=drive config_is_local=true >/dev/null

echo "🔐 Starting MANUAL authentication..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
rclone authorize drive
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⬆️ انسخ الكود كامل (JSON) من الأعلى"

echo "📥 Paste the JSON token and press Enter:"
read -r TOKEN_JSON

rclone config update gdrive token "$TOKEN_JSON" >/dev/null

echo "🧪 Testing connection..."
rclone lsd gdrive: && echo "✅ Google Drive connected successfully!"

echo "🎉 All done!"

