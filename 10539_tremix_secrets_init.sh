#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SECRETS_DIR="$HOME/.config/tremix"
SECRETS_FILE="$SECRETS_DIR/secrets.env"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

# اقرأ المفتاح بدون ما يطلع على الشاشة
printf "🔐 Enter OPENAI_API_KEY (input hidden): "
read -r -s KEY
echo

if [ -z "${KEY:-}" ]; then
  echo "❌ Empty key. Aborting."
  exit 1
fi

# اكتب الملف بصيغة env وبصلاحيات قوية
umask 077
cat > "$SECRETS_FILE" <<EOF
# Tremix Secrets (DO NOT COMMIT)
export OPENAI_API_KEY="$KEY"
# Optional: choose model
export OPENAI_MODEL="gpt-4.1-mini"
EOF

chmod 600 "$SECRETS_FILE"

# اربطه تلقائيًا بكل جلسة Termux
BASHRC="$HOME/.bashrc"
LINE='[ -f "$HOME/.config/tremix/secrets.env" ] && source "$HOME/.config/tremix/secrets.env"'

touch "$BASHRC"
if ! grep -Fq "$LINE" "$BASHRC"; then
  echo "" >> "$BASHRC"
  echo "# Tremix secrets autoload" >> "$BASHRC"
  echo "$LINE" >> "$BASHRC"
fi

echo "✅ Saved: $SECRETS_FILE (chmod 600)"
echo "✅ Linked in: $BASHRC"
echo
echo "Now run:"
echo "  source ~/.bashrc"
echo "  echo \${OPENAI_API_KEY:0:6}******"
