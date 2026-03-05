#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home
# shellcheck disable=SC1091
source .venv/bin/activate

MAIN="app/main.py"
cp -f "$MAIN" "$MAIN.bak2"

python - <<'PY'
import pathlib, re
p = pathlib.Path("app/main.py")
s = p.read_text(encoding="utf-8", errors="ignore")

# Fix broken import line split: ui_route \n r  => ui_router
s = re.sub(r"from\s+app\.web\.router\s+import\s+router\s+as\s+ui_route\s*\n\s*r\s*\n",
           "from app.web.router import router as ui_router\n", s, flags=re.M)

# If it exists but spelled ui_router incorrectly or missing
s = re.sub(r"from\s+app\.web\.router\s+import\s+router\s+as\s+ui_route[r]?\b",
           "from app.web.router import router as ui_router", s)

# Ensure include_router uses ui_router
s = re.sub(r"app\.include_router\(\s*ui_route[r]?\s*\)",
           "app.include_router(ui_router)", s)

p.write_text(s, encoding="utf-8")
print("patched main.py")
PY

python -m py_compile app/main.py
echo "✅ main.py patched and compiles"
