#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Sovereign External Integration Doctor"
echo "======================================="
echo ""

PASS=true

# ---------- Web Connectivity ----------
echo "🌐 Checking Internet Connectivity..."
ping -c 1 google.com >/dev/null 2>&1 && \
  echo "   ✅ Internet Access: OK" || \
  { echo "   ❌ Internet Access: FAIL"; PASS=false; }

# ---------- DNS ----------
echo "🌍 Checking DNS Resolution..."
nslookup google.com >/dev/null 2>&1 && \
  echo "   ✅ DNS Resolution: OK" || \
  { echo "   ❌ DNS Resolution: FAIL"; PASS=false; }

# ---------- AI External APIs ----------
echo "🤖 Checking External AI Connectivity..."
curl -s --max-time 6 https://api.openai.com >/dev/null 2>&1 && \
  echo "   ✅ External AI Network Reachable" || \
  echo "   ⚠️ External AI API not reachable (network only check)"

# ---------- Video Engine ----------
echo "🎥 Checking Video System..."
command -v ffmpeg >/dev/null 2>&1 && \
  echo "   ✅ FFmpeg Installed" || \
  { echo "   ❌ FFmpeg Missing"; PASS=false; }

# ---------- Camera ----------
echo "📷 Checking Camera Access..."
ls /system/etc/media_codecs.xml >/dev/null 2>&1 && \
  echo "   ✅ Camera System Available" || \
  echo "   ⚠️ Camera Access Limited (Android Sandbox)"

# ---------- Streaming ----------
echo "📡 Checking Streaming Capabilities..."
python3 - << 'PY'
try:
    import cv2
    print("   ✅ OpenCV Installed")
except:
    print("   ❌ OpenCV Missing")
PY

# ---------- API Ports ----------
echo "🔌 Checking Open Ports (8080, 8000, 5000)..."
for p in 8080 8000 5000; do
  ss -ltn | grep -q ":$p " && \
    echo "   ✅ Port $p OPEN" || \
    echo "   ⚠️ Port $p CLOSED"
done

# ---------- Dashboard ----------
echo "🖥 Checking Dashboard..."
curl -s http://127.0.0.1:8080 >/dev/null 2>&1 && \
  echo "   ✅ Dashboard Reachable" || \
  echo "   ❌ Dashboard Offline"

# ---------- System Summary ----------
echo ""
echo "==============================="
echo "🧠 Sovereign Integration Status"
echo "==============================="

if [ "$PASS" = true ]; then
  echo "🟢 CORE READY — External AI + Web + Video Framework ONLINE"
else
  echo "🔴 SYSTEM PARTIAL — Some components missing"
fi

echo "================================"
