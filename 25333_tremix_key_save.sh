#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DIR="$HOME/.config/tremix"
FILE="$DIR/secrets.env"
mkdir -p "$DIR"
chmod 700 "$DIR"

echo "🔐 الصق المفتاح الآن (لن يظهر على الشاشة) ثم اضغط Enter:"
read -r -s KEY
echo

if [ -z "${KEY:-}" ]; then
  echo "❌ ما وصلني مفتاح."
  exit 1
fi

umask 077
cat > "$FILE" <<EOF
# Tremix Secrets (DO NOT COMMIT)
export OPENAI_API_KEY="$KEY"
export OPENAI_MODEL="\${OPENAI_MODEL:-gpt-4.1-mini}"
EOF
chmod 600 "$FILE"

BASHRC="$HOME/.bashrc"
LINE='[ -f "$HOME/.config/tremix/secrets.env" ] && source "$HOME/.config/tremix/secrets.env"'
touch "$BASHRC"
grep -Fq "$LINE" "$BASHRC" || {
  echo "" >> "$BASHRC"
  echo "# Tremix secrets autoload" >> "$BASHRC"
  echo "$LINE" >> "$BASHRC"
}

echo "✅ تم الحفظ في: $FILE"
echo "✅ تم الربط في: ~/.bashrc"
echo "شغّل الآن: source ~/.bashrc"
