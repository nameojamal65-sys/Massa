#!/data/data/com.termux/files/usr/bin/bash

echo "🧠 Sovereign Core – All In One Launcher"
echo "======================================"

BASE="$HOME"

echo "🔍 Scanning system..."

# البحث عن sovereign_core
SOV_CORE=$(find $BASE -type d -name "sovereign_core" 2>/dev/null | head -n 1)

if [ -z "$SOV_CORE" ]; then
    echo "❌ sovereign_core not found"
    echo "📁 Searching for system root..."
    ROOT=$(find $BASE -type f -name "main.py" 2>/dev/null | head -n 1 | xargs dirname)
else
    ROOT=$(dirname "$SOV_CORE")
fi

if [ -z "$ROOT" ]; then
    echo "❌ System root not found"
    exit 1
fi

echo "✅ Root found at: $ROOT"
cd "$ROOT" || exit 1

# إضافة PYTHONPATH
export PYTHONPATH="$ROOT:$PYTHONPATH"

echo "🧬 PYTHONPATH set to: $PYTHONPATH"

# فحص المتطلبات
echo "🧪 Checking Python environment..."

python - << 'EOF'
import sys, importlib
mods = ["fastapi","uvicorn","psutil","requests"]
missing=[]
for m in mods:
    try:
        importlib.import_module(m)
    except:
        missing.append(m)
if missing:
    print("⚠️ Missing:", missing)
    sys.exit(1)
else:
    print("✅ All python modules OK")
EOF

if [ $? -ne 0 ]; then
    echo "📦 Installing missing packages..."
    pip install fastapi uvicorn psutil requests --upgrade
fi

# تحديد ملف التشغيل
APP=""

for f in main.py app.py server.py run.py; do
    if [ -f "$f" ]; then
        APP="$f"
        break
    fi
done

if [ -z "$APP" ]; then
    echo "❌ No main startup file found"
    echo "📂 Files here:"
    ls
    exit 1
fi

echo "🚀 Launching system using: $APP"

# تشغيل السيرفر
if grep -q "FastAPI" "$APP"; then
    uvicorn ${APP%.py}:app --host 0.0.0.0 --port 8080 --reload
else
    python "$APP"
fi
