#!/data/data/com.termux/files/usr/bin/bash

echo "🎬 Activating Video Engine"

pkg install -y ffmpeg imagemagick >/dev/null 2>&1
pip install moviepy opencv-python >/dev/null 2>&1

echo "✅ Video Engine Ready"
