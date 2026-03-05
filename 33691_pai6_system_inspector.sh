#!/data/data/com.termux/files/usr/bin/bash

clear
echo "👑 PAI6 — SOVEREIGN SYSTEM INSPECTOR"
echo "===================================="
sleep 1

BASE=~/pai6_sovereign_ui

if [ ! -d "$BASE" ]; then
    echo "❌ PAI6 NOT FOUND at $BASE"
    exit 1
fi

echo "📍 PAI6 Path:"
echo "$BASE"
echo

echo "📦 Total Size:"
du -sh "$BASE"
echo

echo "🗂️ Total Files:"
find "$BASE" -type f | wc -l
echo

echo "📁 Total Directories:"
find "$BASE" -type d | wc -l
echo

echo "🧬 File Types:"
find "$BASE" -type f | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -n 20
echo

echo "🧠 Code Languages:"
echo "------------------"
echo "Python Files:"
find "$BASE" -name "*.py" | wc -l

echo "JS Files:"
find "$BASE" -name "*.js" | wc -l

echo "HTML Files:"
find "$BASE" -name "*.html" | wc -l

echo "CSS Files:"
find "$BASE" -name "*.css" | wc -l

echo "Shell Scripts:"
find "$BASE" -name "*.sh" | wc -l

echo

echo "📏 Lines of Code:"
echo "------------------"
find "$BASE" -name "*.py" -exec wc -l {} + | tail -n 1
echo

echo "⚙️ Core Modules:"
echo "----------------"
find "$BASE" -maxdepth 2 -type d | sed "s|$BASE||"
echo

echo "🔗 External Dependencies:"
echo "--------------------------"
grep -R "import " "$BASE" | cut -d' ' -f2 | cut -d'.' -f1 | sort | uniq | head -n 40
echo

echo "🧪 Heavy Libraries Detection:"
echo "------------------------------"
grep -R -E "torch|tensorflow|opencv|sklearn|jax|transformers|langchain" "$BASE" || echo "No heavy ML libs found"
echo

echo "💾 Device Storage:"
echo "-------------------"
df -h $HOME | tail -n 1
echo

echo "🧠 Memory Status:"
echo "------------------"
free -h
echo

echo "⚡ CPU Info:"
echo "------------"
lscpu 2>/dev/null || cat /proc/cpuinfo | head -n 20
echo

echo "===================================="
echo "🎯 PAI6 SYSTEM ANALYSIS COMPLETE"
echo "===================================="
