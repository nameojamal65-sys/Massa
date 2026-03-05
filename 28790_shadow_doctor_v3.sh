#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🧠 Shadow Doctor v3 — Autonomous Diagnostic Core"
echo "=============================================="
sleep 1

ROOT="$HOME"
REPORT="$ROOT/shadow_report.txt"

echo "📍 Root: $ROOT"
echo "📝 Report: $REPORT"
echo

echo "🧬 System Info" > "$REPORT"
uname -a >> "$REPORT"
echo >> "$REPORT"

echo "📦 Storage Scan..." | tee -a "$REPORT"
du -sh "$ROOT" >> "$REPORT"

echo
echo "🕵️ Searching for AI / UI / Server Files..."

UI=$(find "$ROOT" -type d -iname "*ui*" 2>/dev/null | head -n 1)
WEB=$(find "$ROOT" -type f \( -iname "app.py" -o -iname "main.py" -o -iname "server.py" \) 2>/dev/null | head -n 1)
NODE=$(find "$ROOT" -type f -iname "package.json" 2>/dev/null | head -n 1)

echo "UI_DIR=$UI" >> "$REPORT"
echo "WEB_APP=$WEB" >> "$REPORT"
echo "NODE_APP=$NODE" >> "$REPORT"

echo
echo "⚙️ Environment Scan..."

command -v python >/dev/null && echo "Python: OK" >> "$REPORT" || echo "Python: MISSING" >> "$REPORT"
command -v node >/dev/null && echo "Node: OK" >> "$REPORT" || echo "Node: MISSING" >> "$REPORT"
command -v go >/dev/null && echo "Go: OK" >> "$REPORT" || echo "Go: MISSING" >> "$REPORT"

echo
echo "🔍 Error Patterns Scan..."

grep -R "error\|exception\|traceback\|syntax" "$ROOT" 2>/dev/null | head -n 20 >> "$REPORT"

echo
echo "🚀 Auto Launch Attempt..."

if [[ -n "$WEB" ]]; then
  echo "▶️ Starting Python Web App..."
  python "$WEB" &
elif [[ -n "$NODE" ]]; then
  echo "▶️ Starting Node App..."
  cd "$(dirname "$NODE")" && npm install && npm start &
elif [[ -n "$UI" ]]; then
  echo "⚠️ UI found but no launcher detected"
else
  echo "❌ No runnable system detected"
fi

echo
echo "📊 Final Analysis..."

LINES=$(find "$ROOT" -type f -name "*.py" -o -name "*.js" -o -name "*.go" 2>/dev/null | xargs wc -l 2>/dev/null | tail -n 1)

echo "Total Code Lines: $LINES" >> "$REPORT"

echo
echo "=============================================="
echo "🧠 SHADOW DOCTOR REPORT READY"
echo "📄 $REPORT"
echo "=============================================="
echo
echo "🔎 Summary:"
cat "$REPORT" | tail -n 25
echo
echo "☢️ Shadow Doctor v3 — Mission Complete"
