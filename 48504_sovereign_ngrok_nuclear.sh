#!/data/data/com.termux/files/usr/bin/bash

clear
echo "👑 Sovereign Nuclear Bootstrap — Ngrok Edition"
echo "=============================================="
echo ""

# تحديث البيئة
pkg update -y > /dev/null 2>&1
pkg install wget curl tmux -y > /dev/null 2>&1

# إنشاء مجلد bin إن لم يوجد
mkdir -p ~/bin

# تثبيت ngrok إن لم يكن موجود
if [ ! -f "$HOME/bin/ngrok" ]; then
  echo "⚙️ Installing ngrok..."
  wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm64.tgz
  tar -xzf ngrok-stable-linux-arm64.tgz
  chmod +x ngrok
  mv ngrok ~/bin/
  rm ngrok-stable-linux-arm64.tgz
fi

# إضافة المسار
export PATH=$HOME/bin:$PATH

# طلب التوكن
if [ ! -f "$HOME/.ngrok_token" ]; then
  echo ""
  read -p "🔐 Enter your Ngrok Auth Token: " TOKEN
  echo "$TOKEN" > ~/.ngrok_token
  ngrok config add-authtoken "$TOKEN"
fi

# تفعيل wakelock
termux-wake-lock

# تشغيل النظام
echo ""
echo "🚀 Starting Sovereign Core..."
cd ~/sovereign_system || exit
nohup bash run_global.sh > sovereign_runtime.log 2>&1 &

sleep 6

# تشغيل ngrok داخل tmux
tmux new-session -d -s sovereign_ngrok "ngrok http 8080"

sleep 3

# استخراج الرابط
URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*' | head -n 1)

echo ""
echo "=============================================="
echo "✅ Sovereign System ONLINE"
echo "🌍 Public Dashboard:"
echo ""
echo "$URL"
echo ""
echo "👑 System running in Autonomous Mode"
echo "=============================================="

# منع الإغلاق
while true; do sleep 300; done

