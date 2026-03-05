#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home

echo "======================================"
echo "   🔍 PAI6 Sovereign Engine Audit"
echo "======================================"
echo

# ---------- VENV ----------
if [ -d ".venv" ]; then
  echo "✅ Virtualenv: موجودة"
else
  echo "❌ Virtualenv: غير موجودة"
fi
echo

# ---------- PYTHON ----------
if [ -f ".venv/bin/python" ]; then
  source .venv/bin/activate
  echo "🐍 Python Version:"
  python -V
else
  echo "⚠️  Python غير مفعل"
fi
echo

# ---------- PACKAGES ----------
echo "📦 Core Packages:"
pip list | grep -E "fastapi|uvicorn|sqlalchemy|passlib|pydantic|openai" || true
echo

# ---------- DATABASE ----------
if [ -f "pai6.db" ]; then
  echo "🗄 Database: pai6.db موجودة"
  echo "📊 DB Size:"
  du -h pai6.db
else
  echo "❌ Database غير موجودة"
fi
echo

# ---------- TABLES ----------
if command -v sqlite3 >/dev/null 2>&1 && [ -f "pai6.db" ]; then
  echo "📂 DB Tables:"
  sqlite3 pai6.db ".tables"
else
  echo "⚠️ sqlite3 غير متوفر أو DB غير موجودة"
fi
echo

# ---------- HEALTH CHECK ----------
echo "🌐 Checking /health endpoint..."
if curl -s http://127.0.0.1:9000/health >/dev/null 2>&1; then
  echo "✅ Server Responding"
  curl -s http://127.0.0.1:9000/health
else
  echo "❌ Server Not Running on 9000"
fi
echo
echo

# ---------- AI KEY ----------
echo "🤖 AI Engine Check:"
if [ -n "${OPENAI_API_KEY:-}" ]; then
  echo "✅ OPENAI_API_KEY موجود في البيئة"
else
  echo "⚠️ OPENAI_API_KEY غير موجود"
fi
echo

# ---------- TASKS ----------
if [ -f "pai6.db" ] && command -v sqlite3 >/dev/null 2>&1; then
  echo "🧠 Tasks Count:"
  sqlite3 pai6.db "SELECT COUNT(*) FROM tasks;" 2>/dev/null || echo "⚠️ جدول tasks غير موجود"
fi
echo

# ---------- USERS ----------
if [ -f "pai6.db" ] && command -v sqlite3 >/dev/null 2>&1; then
  echo "👤 Users Count:"
  sqlite3 pai6.db "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "⚠️ جدول users غير موجود"
fi
echo

# ---------- FILES ----------
if [ -f "pai6.db" ] && command -v sqlite3 >/dev/null 2>&1; then
  echo "📁 Files Count:"
  sqlite3 pai6.db "SELECT COUNT(*) FROM file_assets;" 2>/dev/null || echo "⚠️ جدول file_assets غير موجود"
fi
echo

echo "======================================"
echo "   ✅ Audit Complete"
echo "======================================"
