#!/data/data/com.termux/files/usr/bin/bash

clear
echo "👑 PAI6 — NUCLEAR INTELLIGENT SYSTEM INSPECTOR"
echo "============================================="
sleep 1

BASE=~/pai6_sovereign_ui

if [ ! -d "$BASE" ]; then
    echo "❌ PAI6 NOT FOUND at: $BASE"
    exit 1
fi

echo "📍 PAI6 ROOT:"
echo "$BASE"
echo

echo "📦 TOTAL SIZE:"
du -sh "$BASE"
echo

echo "🗂️ FILE COUNT:"
find "$BASE" -type f | wc -l
echo

echo "📁 DIRECTORY COUNT:"
find "$BASE" -type d | wc -l
echo

echo "🧬 FILE TYPES (Top 20):"
find "$BASE" -type f | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -n 20
echo

echo "🧠 CODE LANGUAGES:"
echo "-----------------"
echo "Python:"
find "$BASE" -name "*.py" | wc -l
echo "JavaScript:"
find "$BASE" -name "*.js" | wc -l
echo "HTML:"
find "$BASE" -name "*.html" | wc -l
echo "CSS:"
find "$BASE" -name "*.css" | wc -l
echo "Shell:"
find "$BASE" -name "*.sh" | wc -l
echo "JSON:"
find "$BASE" -name "*.json" | wc -l
echo "YAML:"
find "$BASE" -name "*.yml" -o -name "*.yaml" | wc -l
echo

echo "📏 LINES OF CODE (Top 20 Files):"
find "$BASE" -type f \( -name "*.py" -o -name "*.js" -o -name "*.sh" \) -exec wc -l {} + | sort -nr | head -n 20
echo

echo "🧠 CORE MODULE STRUCTURE:"
echo "-------------------------"
find "$BASE" -maxdepth 3 -type d | sed "s|$BASE||"
echo

echo "🔗 EXTERNAL LIBRARIES (Top 40):"
echo "-------------------------------"
grep -R "import " "$BASE" 2>/dev/null | awk '{print $2}' | cut -d'.' -f1 | sort | uniq | head -n 40
echo

echo "🧪 HEAVY COMPONENT DETECTION:"
echo "-----------------------------"
grep -R -E "torch|tensorflow|jax|opencv|sklearn|transformers|langchain|llama|whisper|onnx" "$BASE" 2>/dev/null || echo "No heavy ML components found"
echo

echo "⚙️ SYSTEM RESOURCE STATUS:"
echo "---------------------------"
echo "Disk:"
df -h $HOME | tail -n 1
echo
echo "Memory:"
free -h
echo
echo "CPU:"
lscpu 2>/dev/null || cat /proc/cpuinfo | head -n 20
echo

echo "🧭 SYSTEM LIMITATIONS:"
echo "-----------------------"
ulimit -a
echo

echo "============================================="
echo "🎯 NUCLEAR INSPECTION COMPLETE"
echo "============================================="
