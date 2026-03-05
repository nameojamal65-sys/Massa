#!/data/data/com.termux/files/usr/bin/bash

clear
echo "🚀 Booting Sovereign Global Launch System..."
echo "========================================="
echo ""

# اختيار البورت تلقائيًا
PORT=8080
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
  PORT=$((PORT+1))
done

echo "🌐 Selected Port: $PORT"
echo "🚀 Launching Sovereign Core..."
echo "-------------------------------------"

# تشغيل السيرفر المحلي (عدّل هذا حسب طريقة تشغيل نظامك)
npm run dev -- --port $PORT >/dev/null 2>&1 &

sleep 3

echo ""
echo "🌍 Opening Global Tunnel..."
echo "-------------------------------------"

ssh -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -R 80:localhost:$PORT serveo.net

