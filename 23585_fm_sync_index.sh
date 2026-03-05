#!/data/data/com.termux/files/usr/bin/sh
set -eu

SRC_ROOT="$HOME/ForgeMind_DRIVE"
CORPUS="$HOME/ForgeMind_DRIVE/data/corpus/_sync"
mkdir -p "$CORPUS"

# امسح النسخة السابقة (اختياري) لتفادي تراكم قديم
rm -rf "$CORPUS"
mkdir -p "$CORPUS"

# انسخ ملفات مفيدة فقط
find "$SRC_ROOT" -maxdepth 6 -type f \
  \( -name "*.go" -o -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" \) \
  ! -path "*/data/*" ! -path "*/.git/*" ! -path "*/downloads/*" ! -path "*/dist/*" \
  -exec cp --parents {} "$CORPUS/" \;

# اعمل فهرسة
forgemindctl index --url http://127.0.0.1:8080 --token fm_dev_token
