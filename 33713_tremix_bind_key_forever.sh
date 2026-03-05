#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/tremix"
SECRETS_FILE="$CONFIG_DIR/secrets.env"
BASHRC="$HOME/.bashrc"

echo "🔐 Tremix Permanent Key Binder"
echo
echo "ألصق المفتاح الآن (لن يظهر على الشاشة) ثم اضغط Enter:"
read -r -s OPENAI_KEY
echo

if [ -z "${OPENAI_KEY:-}" ]; then
  echo "❌ المفتاح فاضي. إلغاء."
  exit 1
fi

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

umask 077
cat > "$SECRETS_FILE" <<EOF
# Tremix Secrets (Permanent)
export OPENAI_API_KEY="$OPENAI_KEY"
export OPENAI_MODEL="\${OPENAI_MODEL:-gpt-4.1-mini}"
EOF

chmod 600 "$SECRETS_FILE"

AUTOLOAD_LINE='[ -f "$HOME/.config/tremix/secrets.env" ] && source "$HOME/.config/tremix/secrets.env"'

touch "$BASHRC"
if ! grep -Fq "$AUTOLOAD_LINE" "$BASHRC"; then
  echo "" >> "$BASHRC"
  echo "# Tremix Auto Load Secrets" >> "$BASHRC"
  echo "$AUTOLOAD_LINE" >> "$BASHRC"
fi

echo
echo "✅ المفتاح انحفظ في:"
echo "   $SECRETS_FILE"
echo
echo "🔒 صلاحيات آمنة مفعّلة (600)"
echo "🔁 مربوط تلقائيًا في ~/.bashrc"
echo
echo "فعّل الآن:"
echo "   source ~/.bashrc"
echo
echo "اختبار سريع:"
echo "   python3 -c \"import os;print('OK' if os.environ.get('OPENAI_API_KEY') else 'NO')\""
