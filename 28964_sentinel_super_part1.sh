#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sentinel_super"
APPDIR="$ROOT/app"

echo "🚀 Sentinel SUPER — PART 1"
echo "📁 Target: $ROOT"

mkdir -p "$APPDIR"
cd "$ROOT"

echo "📦 Installing dependencies..."
pip install --upgrade pip >/dev/null
pip install fastapi uvicorn sqlmodel python-multipart pydantic >/dev/null

touch "$APPDIR/__init__.py"

echo "✅ PART 1 complete."
echo "➡️ Now run: bash sentinel_super_part2.sh"
