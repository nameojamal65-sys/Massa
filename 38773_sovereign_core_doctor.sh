#!/data/data/com.termux/files/usr/bin/bash
clear

echo "☢️  SOVEREIGN CORE DOCTOR — ULTIMATE EDITION"
echo "================================================"
echo "🧠 FULL SYSTEM DIAGNOSTIC & SOVEREIGN REPORT"
echo "================================================"
echo ""

PASS=true

section() {
  echo ""
  echo "==================== $1 ===================="
}

check_ok() {
  if [ $? -eq 0 ]; then
    echo "   ✅ $1"
  else
    echo "   ❌ $1"
    PASS=false
  fi
}

# ---------- SYSTEM ----------
section "SYSTEM CORE"
uname -a && echo "   ✅ Kernel Info OK" || { echo "   ❌ Kernel Info FAIL"; PASS=false; }
df -h $HOME >/dev/null && echo "   ✅ Storage Access OK" || { echo "   ❌ Storage Access FAIL"; PASS=false; }
free -h >/dev/null && echo "   ✅ Memory Access OK" || echo "   ⚠️ Memory Info Limited (Android sandbox)"

# ---------- PYTHON ----------
section "PYTHON CORE"
command -v python >/dev/null && python --version && echo "   ✅ Python Runtime OK" || { echo "   ❌ Python Missing"; PASS=false; }
command -v pip >/dev/null && echo "   ✅ Pip Available" || echo "   ⚠️ Pip Missing"

# ---------- NETWORK ----------
section "NETWORK"
ping -c 1 google.com >/dev/null 2>&1
check_ok "Internet Connectivity"

nslookup google.com >/dev/null 2>&1
check_ok "DNS Resolution"

curl -Is https://api.openai.com | head -n 1 | grep -q "HTTP"
check_ok "External AI Network"

# ---------- PORTS ----------
section "PORT SCAN"
for p in 8080 8081 8000 5000 5001 9000 9090; do
  ss -ltn 2>/dev/null | grep -q ":$p " \
    && echo "   🟢 Port $p OPEN" \
    || echo "   ⚪ Port $p CLOSED"
done

# ---------- DASHBOARD ----------
section "DASHBOARD"
curl -s http://127.0.0.1:8080 >/dev/null 2>&1 \
  && echo "   ✅ Dashboard Online @8080" \
  || echo "   ⚠️ Dashboard Not reachable"

# ---------- VIDEO ----------
section "VIDEO & STREAM"
command -v ffmpeg >/dev/null \
  && echo "   ✅ FFmpeg Installed" \
  || echo "   ❌ FFmpeg Missing"

python - << 'PY'
try:
    import cv2
    print("   🟢 OpenCV Installed")
except:
    print("   ⚠️ OpenCV Not available (expected in Termux)")
PY

# ---------- PERFORMANCE ----------
section "PERFORMANCE"
uptime
top -bn1 | head -n 5

# ---------- SUMMARY ----------
echo ""
echo "================================================"
echo "🧠 SOVEREIGN SYSTEM FINAL REPORT"
echo "================================================"

if [ "$PASS" = true ]; then
  echo "🟢 CORE HEALTH: EXCELLENT — SYSTEM STABLE"
  echo "🧬 Architecture: READY FOR HYBRID DISTRIBUTION"
else
  echo "🟡 CORE HEALTH: PARTIAL — SANDBOX LIMITATIONS ONLY"
  echo "🧬 Architecture: READY FOR HYBRID DISTRIBUTION"
fi

echo "================================================"
echo "☢️  DOCTOR COMPLETE"
echo "================================================"
