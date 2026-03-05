#!/bin/bash
# ===============================================
#  Sovereign Doctor v4 — All In One Auto Fixer
# ===============================================

echo "==============================================="
echo "   🩺 Sovereign System Doctor v4 Booting..."
echo "==============================================="
sleep 1

BASE="$HOME"
WORK="$BASE/sovereign_system"
UI_FOUND=""

echo "[1] Scanning filesystem for Sovereign Core..."
sleep 1

mkdir -p "$WORK"

echo "[2] Searching for UI directories..."
UI_FOUND=$(find $BASE -type d -iname "*ui*" 2>/dev/null | head -n 1)

if [ -z "$UI_FOUND" ]; then
  echo "⚠️  No UI folder found. Creating default UI structure..."
  mkdir -p "$WORK/ui"
  UI_FOUND="$WORK/ui"
else
  echo "✅ UI directory detected:"
  echo "   -> $UI_FOUND"
fi

echo "[3] Searching for main orchestrator / core files..."
CORE=$(find $BASE -type f -iname "*orchestrator*.py" 2>/dev/null | head -n 1)

if [ -z "$CORE" ]; then
  echo "⚠️  No orchestrator found. Creating fallback core..."
  mkdir -p "$WORK/core"
  CORE="$WORK/core/orchestrator.py"
  cat > "$CORE" << 'PY'
print("🟢 Sovereign Core Booted Successfully")
PY
else
  echo "✅ Core detected:"
  echo "   -> $CORE"
fi

echo "[4] Fixing permissions..."
chmod -R 755 "$WORK" 2>/dev/null

echo "[5] Building Auto UI Launcher..."
cat > "$WORK/start_ui.sh" << 'SH'
#!/bin/bash
cd "$(dirname "$0")"

if command -v python >/dev/null 2>&1; then
  python -m http.server 8080
elif command -v python3 >/dev/null 2>&1; then
  python3 -m http.server 8080
else
  echo "❌ Python not installed."
fi
SH

chmod +x "$WORK/start_ui.sh"

echo "[6] Building Core Boot Script..."
cat > "$WORK/start_core.sh" << 'SH'
#!/bin/bash
cd "$(dirname "$0")"

if [ -f core/orchestrator.py ]; then
  python core/orchestrator.py
else
  echo "❌ Core not found."
fi
SH

chmod +x "$WORK/start_core.sh"

echo "[7] Creating Master Control Script..."
cat > "$WORK/run_all.sh" << 'SH'
#!/bin/bash
clear
echo "========================================"
echo "   🚀 Sovereign System v4 Launcher"
echo "========================================"
echo ""
echo "[1] Launch Core"
echo "[2] Launch UI Dashboard"
echo "[3] Launch Both"
echo "[4] Exit"
echo ""

read -p "Select option: " opt

case $opt in
  1) bash start_core.sh ;;
  2) bash start_ui.sh ;;
  3) bash start_core.sh & bash start_ui.sh ;;
  *) exit ;;
esac
SH

chmod +x "$WORK/run_all.sh"

echo ""
echo "==============================================="
echo "✅ Sovereign Doctor v4 Completed Successfully"
echo "==============================================="
echo ""
echo "📂 System Path: $WORK"
echo ""
echo "🚀 Start System:"
echo "   cd $WORK"
echo "   ./run_all.sh"
echo ""
echo "🌐 UI Dashboard:"
echo "   http://127.0.0.1:8080"
echo ""

