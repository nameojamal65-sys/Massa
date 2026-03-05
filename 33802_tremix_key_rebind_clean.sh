#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/tremix"
SECRETS_FILE="$CONFIG_DIR/secrets.env"
BASHRC="$HOME/.bashrc"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

echo "🔐 الصق المفتاح الآن (مخفي) ثم Enter:"
read -r -s KEY
echo

# تنظيف: احذف كل المسافات والأسطر الجديدة
KEY="$(printf "%s" "$KEY" | tr -d '\r\n\t ' )"

if [ -z "$KEY" ]; then
  echo "❌ المفتاح فاضي بعد التنظيف."
  exit 1
fi

umask 077
cat > "$SECRETS_FILE" <<EOF
# Tremix Secrets (Permanent)
export OPENAI_API_KEY="$KEY"
export OPENAI_MODEL="\${OPENAI_MODEL:-gpt-4.1-mini}"
EOF
chmod 600 "$SECRETS_FILE"

AUTOLOAD_LINE='[ -f "$HOME/.config/tremix/secrets.env" ] && source "$HOME/.config/tremix/secrets.env"'
touch "$BASHRC"
grep -Fq "$AUTOLOAD_LINE" "$BASHRC" || {
  echo "" >> "$BASHRC"
  echo "# Tremix Auto Load Secrets" >> "$BASHRC"
  echo "$AUTOLOAD_LINE" >> "$BASHRC"
}

echo "✅ Saved: $SECRETS_FILE"
echo "✅ Now run: source ~/.bashrc"
