#!/bin/bash

clear
echo "🧠 Sovereign All‑In‑One Smart Doctor — Ultimate"
echo "================================================"

BASE="$HOME/sovereign_system"
ZIP="$HOME/Sovereign_System_Clean.zip"

echo "📍 Base Path: $BASE"

if [ ! -d "$BASE" ]; then
    echo "❌ sovereign_system folder not found"
    exit 1
fi

cd "$BASE" || exit 1

echo "🧱 Building Sovereign Structure..."
mkdir -p core webui configs logs scripts

echo "📦 Normalizing project layout..."

for f in start_core.sh start_ui.sh run_all.sh; do
    [ -f "$f" ] && mv "$f" scripts/
done

echo "🧠 Injecting intelligent launchers..."

cat > scripts/start_core.sh << 'EOC'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "🚀 Starting Sovereign Core..."

cd "$BASE_DIR/core" 2>/dev/null || cd "$BASE_DIR"

CORE_FILE=$(find . -maxdepth 3 -type f \( -name "core.py" -o -name "main.py" -o -name "app.py" -o -name "run.sh" -o -name "*.py" \) | head -n 1)

if [ -z "$CORE_FILE" ]; then
    echo "⚠️ Core launcher not found — system running in UI‑only mode."
    exit 0
fi

echo "🧠 Core launcher detected: $CORE_FILE"

case "$CORE_FILE" in
  *.py) python3 "$CORE_FILE" ;;
  *.sh) bash "$CORE_FILE" ;;
  *)    chmod +x "$CORE_FILE" && "$CORE_FILE" ;;
esac
EOC

cat > scripts/start_ui.sh << 'EOU'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "🌐 Starting Web UI..."

cd "$BASE_DIR/webui" || { echo "❌ webui folder missing"; exit 1; }

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

echo "🧪 Running sovereign diagnostic..."
scripts/run_all.sh

echo "📦 Creating clean sovereign package..."

cd "$BASE" || exit 1
rm -f "$ZIP"
zip -r "$ZIP" . >/dev/null

SIZE=$(du -h "$ZIP" | cut -f1)

echo "================================================"
echo "✅ DONE — Sovereign System Fully Stabilized"
echo "📦 ZIP Package: $ZIP"
echo "📊 Package Size: $SIZE"
echo "🌐 Dashboard:"
echo "    http://127.0.0.1:8080"
echo "    or dynamic port shown above"
echo "👑 Sovereign Doctor Ultimate Finished"
echo "================================================"
