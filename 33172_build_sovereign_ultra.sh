#!/bin/bash

echo "🚀 Building Sovereign ULTRA Performance..."

SOURCE_DIR="$HOME/sovereign_production"
ULTRA_DIR="$HOME/sovereign_ultra"
ARCHIVE_NAME="sovereign_ultra_performance.tar.gz"

rm -rf "$ULTRA_DIR"
rm -f "$HOME/$ARCHIVE_NAME"

mkdir -p "$ULTRA_DIR"

echo "📂 Copying project..."
cp -r "$SOURCE_DIR"/* "$ULTRA_DIR"/ 2>/dev/null

cd "$ULTRA_DIR" || exit 1

echo "🐍 Creating optimized venv..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip wheel

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir --prefer-binary -r requirements.txt
fi

# تأكد من وجود gunicorn
pip install gunicorn uvicorn[standard]

deactivate

echo "⚡ Creating ULTRA start script..."

cat > start.sh << 'EOF'
#!/bin/bash

APP_MODULE="core.main:app"

PORT=8080
while lsof -i:$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

echo "🔥 Sovereign ULTRA running on http://127.0.0.1:$PORT"

source venv/bin/activate

exec gunicorn "$APP_MODULE" \
--worker-class uvicorn.workers.UvicornWorker \
--bind 0.0.0.0:$PORT \
--workers 1 \
--preload \
--access-logfile - \
--log-level warning
EOF

chmod +x start.sh

cd "$HOME"
tar -czf "$ARCHIVE_NAME" "$(basename $ULTRA_DIR)"

echo ""
echo "✅ ULTRA PACKAGE READY"
echo "📦 $HOME/$ARCHIVE_NAME"
echo ""
echo "🎯 Run later:"
echo "tar -xzf $ARCHIVE_NAME"
echo "cd sovereign_ultra"
echo "./start.sh"
