#!/data/data/com.termux/files/usr/bin/bash
set -e
echo "🔧 Termux setup (Platform Ultimate++)"
pkg update -y
pkg install -y python git zip openssl termux-tools
# optional media
pkg install -y ffmpeg espeak >/dev/null 2>&1 || true
pip install -r requirements.txt
echo "✅ Termux setup complete"
