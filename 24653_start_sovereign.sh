#!/data/data/com.termux/files/usr/bin/bash

# ====== تشغيل Sovereign Core ======
echo "🚀 Starting Sovereign Core Autonomous System..."
cd ~/sovereign_core

# تشغيل السيرفر إذا لم يكن شغال
if ! pgrep -f "flask run" > /dev/null; then
    bash autostart.sh &
    sleep 5
fi

# ====== اكتشاف IP الجهاز ======
IP=$(ip addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$IP" ]; then
    IP="127.0.0.1"
fi

# ====== فتح المتصفح على لوحة التحكم ======
echo "🌐 Opening Sovereign Dashboard..."
termux-open-url "http://$IP:8080/dashboard"

echo "✅ Sovereign System Fully Online at http://$IP:8080/dashboard"
echo "Press CTRL+C to quit."
