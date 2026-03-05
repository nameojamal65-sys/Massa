#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/tremix"
SECRETS_FILE="$CONFIG_DIR/secrets.env"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

echo "🔐 الصق مفتاح OpenAI الآن (مخفي) ثم Enter:"
echo "⚠️ لازم يبدأ بـ sk- ويكون بسطر واحد."
read -r -s KEY
echo

# تنظيف قوي: احذف كل المسافات/أسطر جديدة/تاب/كاريج
KEY="$(printf "%s" "$KEY" | tr -d '\r\n\t ' )"

# تحقق شكلي
if [ -z "${KEY:-}" ]; then
  echo "❌ المفتاح فاضي بعد التنظيف."
  exit 1
fi
if [[ "$KEY" != sk-* ]]; then
  echo "❌ هذا مش API Key (لا يبدأ بـ sk-)."
  echo "   انسخ المفتاح من Platform (زر Copy) والصقه هنا."
  exit 1
fi

umask 077
cat > "$SECRETS_FILE" <<EOF
# Tremix Secrets (Permanent)
export OPENAI_API_KEY="$KEY"
export OPENAI_MODEL="\${OPENAI_MODEL:-gpt-4.1-mini}"
EOF
chmod 600 "$SECRETS_FILE"

# حمّل المتغير مباشرة داخل الجلسة الحالية
source "$SECRETS_FILE"

echo "✅ تم حفظ المفتاح في: $SECRETS_FILE"
echo "🧪 فحص اتصال حقيقي مع OpenAI..."

python3 - <<'PY'
import os, urllib.request, urllib.error
k=(os.environ.get("OPENAI_API_KEY") or "").strip()
req=urllib.request.Request("https://api.openai.com/v1/models", headers={"Authorization": f"Bearer {k}"})
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        print("✅ HTTP", r.status, "OK (Key works)")
except urllib.error.HTTPError as e:
    print("❌ HTTP", e.code, e.reason)
    print(e.read().decode("utf-8","ignore")[:300])
PY
