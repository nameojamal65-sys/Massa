#!/bin/bash

echo "🔥 Building Sovereign FINAL Binary..."

SOURCE_DIR="$HOME/sovereign_production"
BUILD_DIR="$HOME/sovereign_binary_build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "📂 Copying project..."
cp -r "$SOURCE_DIR"/* "$BUILD_DIR"/ 2>/dev/null

cd "$BUILD_DIR" || exit 1

echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "⚙ Creating launcher..."

cat > launcher.py << 'EOF'
import socket
import uvicorn

def find_free_port(start=8080):
    port = start
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", port)) != 0:
                return port
        port += 1

if __name__ == "__main__":
    port = find_free_port()
    print(f"🚀 Sovereign running on http://127.0.0.1:{port}")
    uvicorn.run("core.main:app", host="0.0.0.0", port=port)
EOF

echo "🧨 Compiling binary..."
pyinstaller --onefile launcher.py

echo ""
echo "✅ Binary Ready:"
echo "$BUILD_DIR/dist/launcher"
echo ""
echo "🎯 Run with:"
echo "cd $BUILD_DIR/dist"
echo "./launcher"



