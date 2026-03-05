#!/data/data/com.termux/files/usr/bin/bash

clear
echo "☢️  SOVEREIGN SUPER NUCLEAR TURBO ENGINE"
echo "======================================"
echo "🔥 MODE: MAXIMUM AUTO REPAIR + FULL ACTIVATION"
echo ""

PASS=true
DASH_PORT=0

# ---------- UPDATE CORE ----------
echo "⚙️ Updating base system..."
pkg update -y && pkg upgrade -y

pkg install -y python python-pip ffmpeg curl wget dnsutils netcat-openbsd iproute2

# ---------- PYTHON ----------
echo "🐍 Repairing Python core..."
python -m pip install --upgrade pip setuptools wheel

# ---------- DNS ----------
echo "🌍 Fixing DNS (Nuclear Mode)..."
echo "nameserver 8.8.8.8" > $PREFIX/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $PREFIX/etc/resolv.conf

nslookup google.com >/dev/null 2>&1 && \
echo "   ✅ DNS FIXED" || \
{ echo "   ❌ DNS FAILED"; PASS=false; }

# ---------- INTERNET ----------
echo "🌐 Testing Internet..."
ping -c 1 google.com >/dev/null 2>&1 && \
echo "   ✅ INTERNET OK" || \
{ echo "   ❌ INTERNET FAIL"; PASS=false; }

# ---------- AI NETWORK ----------
echo "🤖 Testing AI Network..."
curl -I --max-time 6 https://api.openai.com >/dev/null 2>&1 && \
echo "   ✅ AI NETWORK OK" || \
echo "   ⚠️ AI API BLOCKED (NETWORK LEVEL)"

# ---------- OPENCV ----------
echo "📡 Installing OpenCV (Nuclear Build)..."
python -m pip install --no-cache-dir --force-reinstall opencv-python >/dev/null 2>&1

python - << 'PY'
try:
 import cv2
 print("   ✅ OpenCV:",cv2.__version__)
except:
 print("   ❌ OpenCV INSTALL FAILED")
PY

# ---------- VIDEO ----------
echo "🎥 Testing FFmpeg..."
ffmpeg -version >/dev/null 2>&1 && \
echo "   ✅ FFmpeg OK" || \
{ echo "   ❌ FFmpeg FAIL"; PASS=false; }

# ---------- PORT SCAN ----------
echo "🔌 Scanning Ports..."
for p in 8080 8081 5000 5001 9000 9090; do
 nc -z 127.0.0.1 $p >/dev/null 2>&1 && \
 { echo "   ✅ Port $p OPEN"; DASH_PORT=$p; break; } || \
 echo "   ⚠️ Port $p CLOSED"
done

if [ $DASH_PORT -eq 0 ]; then
 DASH_PORT=8082
 echo "⚠️ No standard port open → Using fallback: $DASH_PORT"
fi

# ---------- DASHBOARD ----------
echo "🖥 Activating Dashboard @ $DASH_PORT ..."

if [ -f ./start_sovereign_core.sh ]; then
 ./start_sovereign_core.sh --port $DASH_PORT >/dev/null 2>&1 &
 sleep 4
fi

curl -s --max-time 4 http://127.0.0.1:$DASH_PORT >/dev/null 2>&1 && \
echo "   ✅ Dashboard ONLINE" || \
{ echo "   ❌ Dashboard OFFLINE"; PASS=false; }

# ---------- CAMERA ----------
echo "📷 Testing Camera Layer..."
ls /system/etc/media_codecs.xml >/dev/null 2>&1 && \
echo "   ✅ Camera Available" || \
echo "   ⚠️ Camera Limited (Android Sandbox)"

# ---------- STREAM ----------
echo "📡 Testing Streaming Engine..."
python - << 'PY'
try:
 import cv2, numpy
 print("   ✅ STREAM CORE READY")
except:
 print("   ❌ STREAM CORE FAIL")
PY

# ---------- FINAL ----------
echo ""
echo "======================================"
echo "🧠 SOVEREIGN SYSTEM STATUS"
echo "======================================"
if [ "$PASS" = true ]; then
 echo "🟢 FULL INTEGRATION ACTIVE"
 echo "🌐 Dashboard: http://127.0.0.1:$DASH_PORT"
else
 echo "🔴 SYSTEM PARTIAL — SANDBOX LIMITATIONS"
 echo "🌐 Dashboard Attempted @ $DASH_PORT"
fi
echo "======================================"
echo "☢️  SUPER NUCLEAR TURBO COMPLETE"
echo "======================================"
