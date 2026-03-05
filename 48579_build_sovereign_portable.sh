#!/bin/bash

echo "🔥 Building Sovereign Portable Supreme..."

SOURCE_DIR="$HOME/sovereign_production"
PORTABLE_DIR="$HOME/sovereign_portable"
ARCHIVE_NAME="sovereign_portable_supreme.tar.gz"

# تنظيف النسخ القديمة
rm -rf "$PORTABLE_DIR"
rm -f "$HOME/$ARCHIVE_NAME"

mkdir -p "$PORTABLE_DIR"

echo "📂 Copying project..."
cp -r "$SOURCE_DIR"/* "$PORTABLE_DIR"/ 2>/dev/null

cd "$PORTABLE_DIR" || exit 1

echo "🐍 Creating isolated virtual environment..."
python3 -m venv venv

source venv/bin/activate

echo "📦 Installing dependencies inside venv..."
pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir -r requirements.txt
fi

deactivate

echo "🧠 Creating intelligent start script..."

cat > start.sh << 'EOF'
#!/bin/bash

APP_ENTRY="core.main:app"

# البحث عن بورت فاضي
PORT=8080
while lsof -i:$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

echo "🚀 Sovereign running on http://127.0.0.1:$PORT"

source venv/bin/activate

python3 -m uvicorn $APP_ENTRY --host 0.0.0.0 --port $PORT
EOF

chmod +x start.sh

cd "$HOME"

echo "📦 Compressing portable package..."
tar -czf "$ARCHIVE_NAME" "$(basename $PORTABLE_DIR)"

echo ""
echo "✅ PORTABLE SUPREME READY"
echo "📦 Created:"
echo "$HOME/$ARCHIVE_NAME"
echo ""
echo "🎯 Later usage:"
echo "tar -xzf $ARCHIVE_NAME"
echo "cd sovereign_portable"
echo "./start.sh"
