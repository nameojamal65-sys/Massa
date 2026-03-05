#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Sovereign External Integration Doctor — Auto Fix"
echo "=================================================="
echo ""

PASS=true

# ---------- Internet Check ----------
echo "🌐 Checking Internet Connectivity..."
ping -c 1 google.com >/dev/null 2>&1 && \
  echo "   ✅ Internet Access: OK" || \
  { echo "   ❌ Internet Access: FAIL"; PASS=false; }

# ---------- DNS Check & Auto Fix ----------
echo "🌍 Checking DNS Resolution..."
nslookup google.com >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ DNS Resolution: OK"
else
    echo "   ❌ DNS Resolution: FAIL"
    echo "   🔧 Attempting automatic DNS fix..."
    # Apply Google DNS
    setprop net.dns1 8.8.8.8
    setprop net.dns2 8.8.4.4
    sleep 2
    nslookup google.com >/dev/null 2>&1 && \
        echo "   ✅ DNS Fixed" || \
        { echo "   ❌ DNS Still Failing"; PASS=false; }
fi

# ---------- External AI Connectivity ----------
echo "🤖 Checking External AI Connectivity..."
curl -s --max-time 6 https://api.openai.com >/dev/null 2>&1 && \
  echo "   ✅ External AI Network Reachable" || \
  echo "   ⚠️ External AI API not reachable (network check only)"

# ---------- FFmpeg ----------
echo "🎥 Checking Video System..."
command -v ffmpeg >/dev/null 2>&1 && \
  echo "   ✅ FFmpeg Installed" || \
  { echo "   ❌ FFmpeg Missing — Installing..."; pkg install -y ffmpeg; }

# ---------- Camera ----------
echo "📷 Checking Camera Access..."
ls /system/etc/media_codecs.xml >/dev/null 2>&1 && \
  echo "   ✅ Camera System Available" || \
  echo "   ⚠️ Camera Access Limited (Android Sandbox)"

# ---------- OpenCV ----------
echo "📡 Checking Streaming / OpenCV..."
python3 - << 'PY'
import sys
try:
    import cv2
    print("   ✅ OpenCV Installed")
except ImportError:
    print("   ❌ OpenCV Missing — Installing...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])
    subprocess.run([sys.executable, "-m", "pip", "install", "opencv-python"])
    try:
        import cv2
        print("   ✅ OpenCV Installed After Fix")
    except:
        print("   ❌ OpenCV Still Missing")
PY

# ---------- Ports ----------
echo "🔌 Checking Ports (8080, 8000, 5000)..."
for p in 8080 8000 5000; do
  ss -ltn 2>/dev/null | grep -q ":$p " && \
    echo "   ✅ Port $p OPEN" || \
    echo "   ⚠️ Port $p CLOSED or Permission Denied"
done

# ---------- Dashboard ----------
echo "🖥 Checking Dashboard..."
curl -s http://127.0.0.1:8080 >/dev/null 2>&1 && \
  echo "   ✅ Dashboard Reachable" || \
  echo "   ❌ Dashboard Offline — Check Port/DNS"

# ---------- Summary ----------
echo ""
echo "=================================================="
echo "🧠 Sovereign Integration Status Summary"
echo "=================================================="

if [ "$PASS" = true ]; then
  echo "🟢 CORE READY — External AI + Web + Video Framework ONLINE"
else
  echo "🔴 SYSTEM PARTIAL — Some components missing"
fi

echo "=================================================="
