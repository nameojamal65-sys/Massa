#!/bin/bash
# =========================================
# 🚀 Abu Mftah Super Auto Build
# =========================================
# نسخة ذكية وعنيدة 100% تعتمد على الجلسة الحالية
# Paste in nano: nano abu_mftah_auto.sh
# chmod +x abu_mftah_auto.sh && ./abu_mftah_auto.sh
# =========================================

set -euo pipefail

# -------------------------------
# ⚡️ Retry helper
# -------------------------------
retry() {
    local n=0
    local max=5
    local delay=5
    until "$@"; do
        exit=$?
        n=$((n+1))
        if [ $n -lt $max ]; then
            echo "⚠️ Attempt $n/$max failed. Retrying in $delay sec..."
            sleep $delay
        else
            echo "❌ Command failed after $max attempts: $*"
            return $exit
        fi
    done
}

# -------------------------------
# ✅ Node.js check & install
# -------------------------------
REQUIRED_NODE="18.17.1"
NODE_VER=$(node -v 2>/dev/null | sed 's/v//') || NODE_VER="none"
echo "Detected Node.js: $NODE_VER"
if [[ "$NODE_VER" != "$REQUIRED_NODE" ]]; then
    echo "Installing Node.js $REQUIRED_NODE..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# -------------------------------
# 🔧 Install/update packages
# -------------------------------
retry npm install -g eas-cli expo-cli
retry npm install --legacy-peer-deps
npm audit fix || echo "⚠️ npm audit auto-fix applied"

# -------------------------------
# 🔑 Check EAS session
# -------------------------------
if eas whoami >/dev/null 2>&1; then
    echo "✅ Active EAS session: $(eas whoami)"
else
    echo "❌ No active session. Logging in automatically..."
    read -p "Enter your Expo email: " EXPO_EMAIL
    read -sp "Enter password: " EXPO_PASS
    echo
    retry eas login --username "$EXPO_EMAIL" --password "$EXPO_PASS"
fi

# -------------------------------
# ⚙️ Initialize project if needed
# -------------------------------
if [ ! -f "eas.json" ]; then
    echo "Initializing EAS project..."
    retry eas init --non-interactive
fi

# -------------------------------
# 🏗 Start backend
# -------------------------------
BACKEND_PORT=5000
if lsof -i :$BACKEND_PORT >/dev/null; then
    PID=$(lsof -ti :$BACKEND_PORT)
    kill -9 $PID
fi
echo "Starting backend..."
export FLASK_ENV=production
retry python3 -m flask run --host=0.0.0.0 --port=$BACKEND_PORT &
BACKEND_PID=$!
sleep 5

# -------------------------------
# 📦 Build APK & IPA
# -------------------------------
echo "🚀 Building Android APK..."
retry eas build --platform android --non-interactive --profile production

echo "🚀 Building iOS IPA..."
retry eas build --platform ios --non-interactive --profile production

# -------------------------------
# 🛑 Stop backend
# -------------------------------
kill -9 $BACKEND_PID
echo "Backend stopped."

# -------------------------------
# ✅ Complete
# -------------------------------
echo "🎉 Super Auto Build Complete!"
echo "Backend endpoint: http://localhost:$BACKEND_PORT/api/hello"
