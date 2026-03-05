#!/bin/bash

echo "⚡ Building Sovereign FAST Production..."

SOURCE_DIR="$HOME/sovereign_production"
FAST_DIR="$HOME/sovereign_fast"
ARCHIVE_NAME="sovereign_fast_production.tar.gz"

rm -rf "$FAST_DIR"
rm -f "$HOME/$ARCHIVE_NAME"

mkdir -p "$FAST_DIR"

echo "📂 Copying project..."
cp -r "$SOURCE_DIR"/* "$FAST_DIR"/ 2>/dev/null

cd "$FAST_DIR" || exit 1

echo "🐍 Creating optimized venv..."
python3 -m venv venv

source venv/bin/activate

pip install --upgrade pip wheel

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir --prefer-binary -r requirements.txt
fi

deactivate

echo "⚡ Creating high-performance start script..."

cat > start.sh << 'EOF'
#!/bin/bash

APP_ENTRY="core.main:app"

PORT=8080
while lsof -i:$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

echo "🚀 Sovereign FAST running on http://127.0.0.1:$PORT"

source venv/bin/activate

exec python3 -m uvicorn $APP_ENTRY \
--host 0.0.0.0 \
--port $PORT \
--workers 1 \
--loop uvloop \
--http httptools \
--no-access-log
EOF

chmod +x start.sh

cd "$HOME"
tar -czf "$ARCHIVE_NAME" "$(basename $FAST_DIR)"

echo ""
echo "✅ FAST PACKAGE READY"
echo "📦 $HOME/$ARCHIVE_NAME"
echo ""
echo "🎯 Run later:"
echo "tar -xzf $ARCHIVE_NAME"
echo "cd sovereign_fast"
echo "./start.sh"
