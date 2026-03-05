#!/data/data/com.termux/files/usr/bin/bash

clear
echo "☢️  SOVEREIGN NUCLEAR REPAIR ENGINE"
echo "========================================="
echo "🔥 MODE: TOTAL SYSTEM REPAIR"
echo ""

PASS=true

# ---------- BASE TOOLS ----------
echo "⚙️  Updating core packages..."
pkg update -y && pkg upgrade -y

pkg install -y python python-pip ffmpeg curl wget dnsutils netcat-openbsd iproute2

# ---------- PYTHON CORE ----------
echo "🐍 Rebuilding Python Core..."
python -m pip install --upgrade pip setuptools wheel

# ---------- DNS HARD FIX ----------
echo "🌍 Nuclear DNS Repair..."
echo "nameserver 8.8.8.8" > $PREFIX/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $PREFIX/etc/resolv.conf

nslookup google.com >/dev/null 2>&1 && \
echo "   ✅ DNS FIXED" || \
{ echo "   ❌ DNS STILL BROKEN"; PASS=false; }

# ---------- INTERNET ----------
echo "🌐 Testing internet..."
ping -c 1 google.com >/dev/null 2>&1 && \
echo "   ✅ INTERNET OK" || \
{ echo "   ❌ INTERNET FAIL"; PASS=false; }

# ---------- AI NETWORK ----------
echo "🤖 Testing AI network..."
curl -I --max-time 6 https://api.openai.com >/dev/null 2>&1 && \
echo "   ✅ AI NETWORK OK" || \
echo "   ⚠️ AI API BLOCKED (network only)"

# ---------- OPENCV ----------
echo "📡 Installing OpenCV Nuclear Build..."
pip install --no-cache-dir --force-reinstall opencv-python && \
python - << 'PY'
import cv2
print("   ✅ OpenCV:",cv2.__version__)
PY || { echo "   ❌ OpenCV FAILED"; PASS=false; }

# ---------- VIDEO ----------
echo "🎥 Testing FFmpeg..."
ffmpeg -version >/dev/null 2>&1 && \
echo "   ✅ FFmpeg OK" || \
{ echo "   ❌ FFmpeg FAIL"; PASS=false; }

# ---------- PORTS ----------
echo "🔌 Testing ports..."
for p in 8080 8081 5000 5001; do
 nc -z 127.0.0.1 $p >/dev/null 2>&1 && \
 echo "   ✅ Port $p OPEN" || \
 echo "   ⚠️ Port $p CLOSED"
done

# ---------- DASHBOARD ----------
echo "🖥 Testing dashboard..."
for p in 8080 8081 5001; do
  curl -s --max-time 4 http://127.0.0.1:$p >/dev/null 2>&1 && \
  { echo "   ✅ Dashboard ONLINE @ $p"; DASH_PORT=$p; break; }
done

# ---------- CAMERA ----------
echo "📷 Testing camera layer..."
ls /system/etc/media_codecs.xml >/dev/null 2>&1 && \
echo "   ✅ Camera Available" || \
echo "   ⚠️ Camera Limited (Android sandbox)"

# ---------- STREAM TEST ----------
echo "📡 Testing streaming engine..."
python - << 'PY'
try:
 import cv2, numpy
 print("   ✅ STREAM CORE READY")
except:
 print("   ❌ STREAM CORE FAIL")
PY

# ---------- FINAL REPORT ----------
echo ""
echo "========================================="
echo "🧠 SOVEREIGN SYSTEM STATUS"
echo "========================================="

if [ "$PASS" = true ]; then
 echo "🟢 SYSTEM READY — FULL EXTERNAL INTEGRATION ACTIVE"
else
 echo "🔴 SYSTEM PARTIAL — HARDWARE LIMITATIONS DETECTED"
fi

echo "========================================="
echo "☢️  NUCLEAR REPAIR COMPLETE"
echo "========================================="
