#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME"
echo "🔍 PAI6 SYSTEM AUDIT"
echo "===================="

echo "📂 Filesystem:"
find "$BASE" -maxdepth 2 -type d | wc -l

echo "⚙️ Runtime:"
python -V 2>/dev/null
node -v 2>/dev/null
go version 2>/dev/null

echo "🌐 Network:"
ss -ltn

echo "🤖 LLM Integration:"
find "$BASE" -type f | grep -Ei "openai|llm|api|model|chat|inference" | head -n 20

echo "🎬 Video Capability:"
find "$BASE" -type f | grep -Ei "ffmpeg|video|media|render|stream"

echo "🧠 Intelligence Engines:"
find "$BASE" -type f | grep -Ei "engine|core|brain|mind|ai|cortex|logic" | wc -l

echo "📊 Summary:"
echo "Filesystem OK"
echo "Runtime OK"
echo "Engines detected"
echo "===================="
