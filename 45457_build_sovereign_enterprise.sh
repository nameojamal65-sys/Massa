#!/bin/bash

echo "🏢 Building Sovereign ENTERPRISE Runtime..."

SOURCE_DIR="$HOME/sovereign_production"
ENT_DIR="$HOME/sovereign_enterprise"
ARCHIVE_NAME="sovereign_enterprise_runtime.tar.gz"

rm -rf "$ENT_DIR"
rm -f "$HOME/$ARCHIVE_NAME"

mkdir -p "$ENT_DIR"

echo "📂 Copying project..."
cp -r "$SOURCE_DIR"/* "$ENT_DIR"/ 2>/dev/null

cd "$ENT_DIR" || exit 1

echo "🐍 Creating production venv..."
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip wheel

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir --prefer-binary -r requirements.txt
fi

pip install gunicorn uvicorn[standard]

deactivate

echo "🧠 Creating enterprise launcher..."

cat > server.sh << 'EOF'
#!/bin/bash

APP_MODULE="core.main:app"
PORT=8080

while lsof -i:$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

echo "$(date) 🚀 Starting Sovereign Enterprise on port $PORT" >> server.log

source venv/bin/activate

exec gunicorn "$APP_MODULE" \
--worker-class uvicorn.workers.UvicornWorker \
--bind 0.0.0.0:$PORT \
--workers 1 \
--preload \
--log-level warning \
>> server.log 2>&1
EOF

chmod +x server.sh

echo "🛡 Creating crash-guard auto-restart..."

cat > start.sh << 'EOF'
#!/bin/bash

echo "🛡 Sovereign Enterprise Runtime Active"

while true
do
  ./server.sh
  echo "$(date) ⚠ Crash detected. Restarting in 3s..." >> server.log
  sleep 3
done
EOF

chmod +x start.sh

echo "⚙ Creating daemon launcher..."

cat > daemon.sh << 'EOF'
#!/bin/bash

nohup ./start.sh > /dev/null 2>&1 &
echo "🔥 Sovereign Enterprise running in background"
EOF

chmod +x daemon.sh

cd "$HOME"
tar -czf "$ARCHIVE_NAME" "$(basename $ENT_DIR)"

echo ""
echo "✅ ENTERPRISE PACKAGE READY"
echo "📦 $HOME/$ARCHIVE_NAME"
echo ""
echo "🎯 Usage:"
echo "tar -xzf $ARCHIVE_NAME"
echo "cd sovereign_enterprise"
echo "./start.sh        # foreground"
echo "./daemon.sh       # background"
