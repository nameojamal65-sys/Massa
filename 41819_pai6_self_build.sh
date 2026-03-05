#!/bin/bash
# ============================================================
# 👑 PAI6 — ONE SHOT SELF BUILD APK
# ============================================================

set -e

echo ""
echo "🚀 PAI6 — Autonomous Self APK Builder"
echo "=============================================="

BASE="$HOME/pai6_autobuilder"
OUT="$BASE/output"
LOG="$BASE/logs"
APK="PAI6_SELF.apk"

mkdir -p "$OUT" "$LOG"

logfile="$LOG/build_$(date +%Y%m%d_%H%M%S).log"

echo "🔍 Checking system..."

for bin in node npm python java; do
    if ! command -v $bin >/dev/null 2>&1; then
        echo "❌ Missing: $bin"
        exit 1
    fi
done

echo "✅ Environment OK"

if [ ! -f "$BASE/build_all.sh" ]; then
    echo "❌ build_all.sh not found at: $BASE"
    exit 1
fi

chmod +x "$BASE/build_all.sh"

echo ""
echo "⚙️ Building APK..."
cd "$BASE"
bash build_all.sh apk 2>&1 | tee "$logfile"

echo ""
echo "🔎 Searching for APK..."

apk=$(find "$BASE" -type f -iname "*.apk" | head -n 1)

if [ -z "$apk" ]; then
    echo "❌ APK not generated!"
    exit 1
fi

mv "$apk" "$OUT/$APK"

echo ""
echo "=============================================="
echo "🎯 SUCCESS — PAI6 BUILT ITSELF"
echo "=============================================="
echo "📦 APK: $OUT/$APK"
echo "📝 LOG: $logfile"
echo "=============================================="
echo ""
