#!/data/data/com.termux/files/usr/bin/bash
# ==============================================
# 👑 PAI6 Sovereign Intelligence Analyzer
# ==============================================

ROOT=${1:-$(pwd)}
TS=$(date +%s)
REPORT="$ROOT/pai6_sovereign_report_$TS.txt"

echo "👑 PAI6 Sovereign Intelligence Scanner"
echo "===================================="
echo "ROOT: $ROOT"
echo ""

SIZE=$(du -sh "$ROOT" 2>/dev/null | awk '{print $1}')
FILES_COUNT=$(find "$ROOT" -type f 2>/dev/null | wc -l)
DIRS_COUNT=$(find "$ROOT" -type d 2>/dev/null | wc -l)

RAW_LINES=$(find "$ROOT" -type f \
 ! -path "*/node_modules/*" \
 ! -path "*/venv/*" \
 ! -path "*/.git/*" \
 ! -path "*/__pycache__/*" \
 -exec cat {} + 2>/dev/null | wc -l)

CODE_LINES=$(find "$ROOT" -type f \( \
 -name "*.py" -o -name "*.js" -o -name "*.ts" \
 -o -name "*.go" -o -name "*.rs" -o -name "*.java" \
 -o -name "*.c" -o -name "*.cpp" -o -name "*.sh" \
 \) ! -path "*/node_modules/*" \
    ! -path "*/venv/*" \
    ! -path "*/.git/*" \
 -exec cat {} + 2>/dev/null | wc -l)

ENDPOINTS=$(grep -RhoE "(GET|POST|PUT|DELETE|PATCH)[\"' ]+\/*[a-zA-Z0-9_\/\-{}:]+" "$ROOT" 2>/dev/null | sort -u | wc -l)

ENTRY_POINTS=$(find "$ROOT" -type f \( \
 -name "main.py" -o -name "app.py" -o -name "server.py" \
 -o -name "index.js" -o -name "main.js" -o -name "run*.sh" \
 \) 2>/dev/null | wc -l)

ENGINES=$(find "$ROOT" -type d | grep -Ei "engine|core|kernel|brain|mind|agent|planner|executor|orchestrator" | wc -l)

INTELLIGENCE_SCORE=$(( (CODE_LINES / 1000) + (ENGINES * 5) + (ENDPOINTS * 2) ))

if   [ $INTELLIGENCE_SCORE -lt 50 ];   then LEVEL="Low"
elif [ $INTELLIGENCE_SCORE -lt 200 ];  then LEVEL="Medium"
elif [ $INTELLIGENCE_SCORE -lt 600 ];  then LEVEL="High"
elif [ $INTELLIGENCE_SCORE -lt 1500 ]; then LEVEL="Advanced"
else LEVEL="Sovereign"
fi

if [ $INTELLIGENCE_SCORE -gt 800 ]; then
  CLASSIFICATION="Autonomous AI Operating System"
elif [ $INTELLIGENCE_SCORE -gt 400 ]; then
  CLASSIFICATION="Enterprise AI Platform"
elif [ $INTELLIGENCE_SCORE -gt 150 ]; then
  CLASSIFICATION="Advanced AI System"
else
  CLASSIFICATION="Standard Software Platform"
fi

VULNS=$(grep -RinE "eval\(|exec\(|pickle\.loads|subprocess\.Popen|shell=True|os.system|jwt.decode\(" "$ROOT" 2>/dev/null | wc -l)

{
echo "👑 PAI6 Sovereign Intelligence Report"
echo "===================================="
echo "📦 System Size            : $SIZE"
echo "📁 Total Files            : $FILES_COUNT"
echo "📂 Total Directories      : $DIRS_COUNT"
echo "🧾 Raw Lines              : $RAW_LINES"
echo "🧠 Pure Code Lines        : $CODE_LINES"
echo "🔌 Endpoints              : $ENDPOINTS"
echo "🚀 Entry Points           : $ENTRY_POINTS"
echo "⚙️  Engines / Cores        : $ENGINES"
echo ""
echo "🧠 Intelligence Score     : $INTELLIGENCE_SCORE"
echo "🎯 Intelligence Level     : $LEVEL"
echo "🏷️  Classification        : $CLASSIFICATION"
echo ""
echo "🛡️ Potential Vuln Points  : $VULNS"
echo "===================================="
} | tee "$REPORT"

echo ""
echo "📄 Report saved at: $REPORT"
