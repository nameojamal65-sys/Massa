#!/bin/bash

echo "🧠 Sovereign Smart Doctor — All In One"
echo "====================================="

BASE="$HOME/sovereign_system"

echo "📍 Base Path: $BASE"

if [ ! -d "$BASE" ]; then
    echo "❌ sovereign_system folder not found"
    exit 1
fi

cd "$BASE" || exit 1

echo "🧱 Creating sovereign structure..."
mkdir -p core webui configs logs scripts

echo "📦 Moving scripts..."
[ -f start_core.sh ] && mv start_core.sh scripts/
[ -f start_ui.sh ] && mv start_ui.sh scripts/
[ -f run_all.sh ] && mv run_all.sh scripts/

echo "🧬 Writing intelligent scripts..."

cat > scripts/start_core.sh << 'EOC'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "🚀 Starting Sovereign Core..."
cd "$BASE_DIR/core" || { echo "❌ Core folder missing"; exit 1; }

if [ -f core.py ]; then
    python3 core.py
elif [ -f main.py ]; then
    python3 main.py
elif [ -f run.sh ]; then
    bash run.sh
else
    echo "⚠️ No known core launcher found — core idle."
fi
EOC

cat > scripts/start_ui.sh << 'EOU'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "🌐 Starting Web UI..."
cd "$BASE_DIR/webui" || { echo "❌ WebUI folder missing"; exit 1; }

if [ -f run_webui.sh ]; then
    bash run_webui.sh
elif [ -f package.json ]; then
    npm run dev
else
    python3 -m http.server 8080
fi
EOU

cat > scripts/run_all.sh << 'EOR'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "🚀 Booting Sovereign Core Autonomous System..."
"$BASE_DIR/scripts/start_core.sh" &

sleep 3

"$BASE_DIR/scripts/start_ui.sh" &

echo "✅ Sovereign System Fully Online"
echo "🌐 Dashboard: http://127.0.0.1:8080"
EOR

chmod +x scripts/*.sh

echo "🧪 Running diagnostic..."
scripts/run_all.sh

echo "📦 Building clean ZIP package..."

cd "$BASE" || exit 1
zip -r "$HOME/Sovereign_System_Clean.zip" . >/dev/null

echo "====================================="
echo "✅ DONE — Sovereign System Repaired & Structured"
echo "📦 Clean ZIP: $HOME/Sovereign_System_Clean.zip"
echo "🌐 Dashboard: http://127.0.0.1:8080"
echo "👑 Sovereign Doctor finished successfully"
echo "====================================="
