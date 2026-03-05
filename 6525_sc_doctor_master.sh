#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/sovereign_core}"
cd "$PROJECT_DIR"

echo "🩺 Sovereign Core Doctor Master"
echo "📁 Project: $PROJECT_DIR"
echo "🐍 Python:  $(command -v python3)"
python3 -V || true
echo

fail() { echo "❌ $*" >&2; exit 1; }
ok()   { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }

# 1) Basic structure checks
test -d "sc_ops" || fail "مجلد sc_ops غير موجود داخل المشروع."
test -f "sc_ops/__init__.py" || warn "sc_ops/__init__.py غير موجود (سأحاول إنشاءه)."

if [ ! -f "sc_ops/__init__.py" ]; then
  touch "sc_ops/__init__.py"
  ok "تم إنشاء sc_ops/__init__.py"
fi

test -d "sc_ops/store" || fail "مجلد sc_ops/store غير موجود."

# 2) Confirm Python can locate sc_ops
echo "🔎 Checking Python spec for sc_ops..."
python3 - <<'PY'
import importlib.util
spec = importlib.util.find_spec("sc_ops")
print("spec =", spec)
PY
echo

# 3) Snapshot current store __init__
STORE_INIT="sc_ops/store/__init__.py"
BACKUP="$STORE_INIT.bak.$(date +%Y%m%d_%H%M%S)"
cp -f "$STORE_INIT" "$BACKUP"
ok "Backup created: $BACKUP"

echo "📄 Current $STORE_INIT (first 120 lines):"
sed -n '1,120p' "$STORE_INIT" || true
echo

# 4) Find get_store definition
echo "🔎 Searching for: def get_store ..."
GET_STORE_DEF="$(grep -Rns "^[[:space:]]*def[[:space:]]\+get_store[[:space:]]*(" sc_ops/store sc_ops 2>/dev/null | head -n 1 || true)"

if [ -n "$GET_STORE_DEF" ]; then
  ok "Found get_store definition at: $GET_STORE_DEF"
  FILE_PATH="$(echo "$GET_STORE_DEF" | cut -d: -f1)"
  MOD_PATH="${FILE_PATH#sc_ops/}"
  MOD_PATH="${MOD_PATH%.py}"
  MOD_PATH="${MOD_PATH//\//.}"   # e.g. store/sqlite.py -> store.sqlite
  # We want relative import from store package:
  # from .sqlite import get_store   (if module is store.sqlite)
  REL_MOD="${MOD_PATH#store.}"     # remove leading "store."
  if [ "$REL_MOD" = "$MOD_PATH" ]; then
    # If it wasn't under store/, fallback:
    REL_MOD="$MOD_PATH"
  fi

  # Ensure export in store/__init__.py
  if grep -qE "get_store" "$STORE_INIT"; then
    warn "يبدو أن __init__.py يحتوي على get_store بالفعل. سأحاول إصلاحه بشكل نظيف."
  fi

  # Remove previous get_store export lines to avoid duplicates/conflicts
  TMP="$(mktemp)"
  awk '
    !($0 ~ /get_store/ && ($0 ~ /from[[:space:]]+\./ || $0 ~ /import[[:space:]]+get_store/))
  ' "$STORE_INIT" > "$TMP"
  mv "$TMP" "$STORE_INIT"

  echo >> "$STORE_INIT"
  echo "# --- Doctor Master: export get_store ---" >> "$STORE_INIT"
  echo "from .${REL_MOD} import get_store  # auto-added" >> "$STORE_INIT"
  ok "Patched: $STORE_INIT -> from .${REL_MOD} import get_store"
else
  warn "لم أجد def get_store. سأبحث عن بدائل (make_store/open_store/create_store...)."

  ALT_LINE="$(grep -Rns "^[[:space:]]*def[[:space:]]\+\(make_store\|open_store\|create_store\|build_store\|get_sqlite_store\|get_db_store\)[[:space:]]*(" sc_ops/store sc_ops 2>/dev/null | head -n 1 || true)"

  if [ -z "$ALT_LINE" ]; then
    echo
    echo "📦 Files under sc_ops/store:"
    ls -la sc_ops/store || true
    echo
    fail "لا يوجد get_store ولا بدائل واضحة. لازم نعرف أي دالة تمثل الـ store factory."
  fi

  ok "Found alternative store factory at: $ALT_LINE"
  FILE_PATH="$(echo "$ALT_LINE" | cut -d: -f1)"
  FUNC_NAME="$(echo "$ALT_LINE" | sed -E 's/.*def[[:space:]]+([a-zA-Z0-9_]+).*/\1/')"

  MOD_PATH="${FILE_PATH#sc_ops/}"
  MOD_PATH="${MOD_PATH%.py}"
  MOD_PATH="${MOD_PATH//\//.}"

  REL_MOD="${MOD_PATH#store.}"
  if [ "$REL_MOD" = "$MOD_PATH" ]; then
    REL_MOD="$MOD_PATH"
  fi

  # Clean conflicting exports
  TMP="$(mktemp)"
  awk '
    !($0 ~ /get_store/ && ($0 ~ /from[[:space:]]+\./ || $0 ~ /import[[:space:]]+get_store/))
  ' "$STORE_INIT" > "$TMP"
  mv "$TMP" "$STORE_INIT"

  echo >> "$STORE_INIT"
  echo "# --- Doctor Master: alias ${FUNC_NAME} as get_store ---" >> "$STORE_INIT"
  echo "from .${REL_MOD} import ${FUNC_NAME} as get_store  # auto-added" >> "$STORE_INIT"
  ok "Patched: $STORE_INIT -> from .${REL_MOD} import ${FUNC_NAME} as get_store"
fi

echo
echo "🧪 Testing import sc_ops.api ..."
set +e
python3 -c "import sc_ops.api; print('OK: sc_ops.api import')"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo
  echo "❌ ما زال الاستيراد يفشل. هذا يعني أن داخل sc_ops.api أو اعتماداته خطأ آخر."
  echo "📌 شغّل هذا لإظهار التتبع كامل:"
  echo "    cd $PROJECT_DIR && python3 -c \"import sc_ops.api\""
  echo
  echo "📄 $STORE_INIT after patch (first 160 lines):"
  sed -n '1,160p' "$STORE_INIT" || true
  exit 2
fi

ok "Import fixed ✅"

echo
echo "🌐 Port check (8080):"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep ':8080' && ok "8080 is listening" || warn "8080 NOT listening (server may not be running)."
else
  warn "ss غير متوفر. جرّب: lsof -iTCP:8080 -sTCP:LISTEN"
fi

echo
echo "✅ Doctor Master completed."
echo "👉 إذا السيرفر ما زال لا يعمل، شغّل سكربت الإقلاع بعد الإصلاح:"
echo "   cd $PROJECT_DIR && ./boot.sh"
