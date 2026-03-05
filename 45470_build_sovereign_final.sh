#!/bin/bash

echo "🏆 Building Sovereign FINAL Hardened Server..."

SOURCE_DIR="$HOME/sovereign_production"
FINAL_DIR="$HOME/sovereign_final"
ARCHIVE_NAME="sovereign_final_server.tar.gz"

rm -rf "$FINAL_DIR"
rm -f "$HOME/$ARCHIVE_NAME"

mkdir -p "$FINAL_DIR"
cp -r "$SOURCE_DIR"/* "$FINAL_DIR"/ 2>/dev/null

cd "$FINAL_DIR" || exit 1

# ================= VENV =================
python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip wheel
pip install gunicorn uvicorn[standard] psutil python-dotenv slowapi

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir --prefer-binary -r requirements.txt
fi

deactivate

# ================= CONFIG =================
cat > config.env << 'EOF'
PORT=8443
WORKERS=1
USERNAME=admin
PASSWORD=sovereign123
API_KEY=supersecurekey
RATE_LIMIT=10/minute
EOF

# ================= SSL =================
mkdir -p ssl
openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout ssl/key.pem \
-out ssl/cert.pem \
-subj "/C=US/ST=Server/L=Local/O=Sovereign/OU=AI/CN=localhost"

# ================= HEALTH CHECK =================
cat > health.py << 'EOF'
from fastapi import APIRouter
router = APIRouter()

@router.get("/health")
async def health():
    return {"status": "ok"}
EOF

# ================= SERVER =================
cat > server.sh << 'EOF'
#!/bin/bash

source config.env
source venv/bin/activate

ulimit -n 4096

while lsof -i:$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done

echo "$(date) 🚀 Starting FINAL on port $PORT" >> server.log

exec gunicorn core.main:app \
--worker-class uvicorn.workers.UvicornWorker \
--bind 0.0.0.0:$PORT \
--workers $WORKERS \
--preload \
--certfile ssl/cert.pem \
--keyfile ssl/key.pem \
--log-level warning \
>> server.log 2>&1
EOF

chmod +x server.sh

# ================= MANAGER =================
cat > sovereign << 'EOF'
#!/bin/bash

case "$1" in
  start)
    nohup ./server.sh > /dev/null 2>&1 &
    echo "🔥 Sovereign FINAL started (HTTPS)"
    ;;
  stop)
    pkill -f gunicorn
    echo "🛑 Stopped"
    ;;
  restart)
    pkill -f gunicorn
    sleep 2
    nohup ./server.sh > /dev/null 2>&1 &
    echo "♻ Restarted"
    ;;
  status)
    pgrep -f gunicorn >/dev/null && echo "✅ Running" || echo "❌ Stopped"
    ;;
  logs)
    tail -f server.log
    ;;
  monitor)
    watch -n 1 "ps -o pid,cmd,%cpu,%mem -C gunicorn"
    ;;
  *)
    echo "Usage: ./sovereign {start|stop|restart|status|logs|monitor}"
    ;;
esac
EOF

chmod +x sovereign

# ================= AUTO BOOT =================
mkdir -p ~/.termux/boot

cat > ~/.termux/boot/sovereign_boot.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/sovereign_final
./sovereign start
EOF

chmod +x ~/.termux/boot/sovereign_boot.sh

cd "$HOME"
tar -czf "$ARCHIVE_NAME" "$(basename $FINAL_DIR)"

echo ""
echo "🏆 FINAL SERVER READY"
echo "📦 $HOME/$ARCHIVE_NAME"
echo ""
echo "🎯 Usage:"
echo "tar -xzf $ARCHIVE_NAME"
echo "cd sovereign_final"
echo "./sovereign start"
