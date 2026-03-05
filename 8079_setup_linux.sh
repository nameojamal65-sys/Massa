#!/usr/bin/env bash
set -e
echo "🔧 Linux setup (Platform Ultimate++)"
sudo apt update -y
sudo apt install -y python3 python3-pip zip openssl
sudo apt install -y ffmpeg espeak >/dev/null 2>&1 || true
pip3 install -r requirements.txt
echo "✅ Linux setup complete"
