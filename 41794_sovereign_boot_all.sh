#!/bin/bash
# =========================================
# 🚀 Sovereign Core All-In-One Launcher
# =========================================

echo "🧠 Starting Sovereign Core..."
echo "====================================="
sleep 1

# 1️⃣ Check Root
if [ "$(whoami)" != "root" ]; then
    echo "⚠️ Warning: Not running as root. Some features may fail."
else
    echo "✅ Root access confirmed."
fi
sleep 1

# 2️⃣ Set PYTHONPATH
export PYTHONPATH="$HOME:$PYTHONPATH"
echo "🧬 PYTHONPATH set to: $PYTHONPATH"
sleep 1

# 3️⃣ Verify Python environment
echo "🧪 Checking Python environment..."
REQUIRED_MODULES=("flask" "requests" "psutil")
for mod in "${REQUIRED_MODULES[@]}"; do
    python3 -c "import $mod" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ Python module $mod OK"
    else
        echo "❌ Python module $mod missing"
    fi
done
sleep 1

# 4️⃣ Detect main Sovereign files
echo "📂 Scanning for main Sovereign files..."
MAIN_FILE=""
for f in "$HOME"/pai6_sovereign_ui "$HOME"/pai6_sovereign_core; do
    if [ -f "$f" ]; then
        MAIN_FILE="$f"
        break
    fi
done

if [ -z "$MAIN_FILE" ]; then
    echo "❌ No main startup file found!"
    echo "📂 Please ensure pai6_sovereign_core or pai6_sovereign_ui exists in $HOME"
    exit 1
else
    echo "✅ Found main file: $MAIN_FILE"
fi
sleep 1

# 5️⃣ Launch Core & UI
echo "🚀 Launching Sovereign Core & UI..."
$MAIN_FILE &
sleep 2

# 6️⃣ Dashboard Link
echo "🌐 Dashboard should be available at: http://127.0.0.1:8080"
echo "====================================="
echo "✅ Sovereign System Fully Online!"
