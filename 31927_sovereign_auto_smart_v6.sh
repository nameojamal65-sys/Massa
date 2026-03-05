#!/data/data/com.termux/files/usr/bin/bash
# 🔹 Sovereign Auto Smart Build v6 for Termux 🔹

echo "🚀 Starting Sovereign Auto Smart Build v6..."

# ---- Node.js ----
REQUIRED_NODE="18.17.1"
echo "🖥 Checking Node.js version..."
if ! command -v nvm &> /dev/null; then
    echo "🔧 Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

unset PREFIX  # Fix e_type error
nvm install $REQUIRED_NODE
nvm use $REQUIRED_NODE
echo "✅ Node.js version set to $(node -v)"

# ---- Check / free backend port ----
PORT=5000
if lsof -i:$PORT &>/dev/null; then
    echo "⚠️ Port $PORT in use, killing process..."
    kill -9 $(lsof -t -i:$PORT)
fi

# ---- Install / update npm packages ----
echo "📦 Installing npm packages..."
npm install --legacy-peer-deps
npm audit fix --force

# ---- React & React Native update ----
echo "⚠️ Updating React & React Native..."
npx react-native upgrade --legacy-peer-deps || echo "No updates needed"

# ---- EAS / Expo setup ----
echo "🔑 Checking EAS CLI..."
if ! command -v eas &> /dev/null; then
    npm install -g eas-cli
fi

echo "📂 Initializing EAS project if needed..."
if [ ! -f eas.json ]; then
    eas init --non-interactive
fi

# ---- Login to Expo automatically ----
EXPO_TOKEN="ضع_توكن_Expo_هنا"
if [ -n "$EXPO_TOKEN" ]; then
    export EXPO_TOKEN=$EXPO_TOKEN
    echo "🔑 Using provided Expo token"
else
    echo "⚠️ No Expo token set, login required manually"
fi

# ---- Start backend ----
echo "🖥 Starting backend..."
if [ -f backend/main.py ]; then
    python3 backend/main.py &
    BACKEND_PID=$!
else
    echo "⚠️ Backend not found, creating dummy server..."
    python3 -m http.server $PORT &
    BACKEND_PID=$!
fi
sleep 3

# ---- Build APK ----
echo "📦 Building Android APK via EAS..."
eas build --platform android --non-interactive --profile production

# ---- Build IPA (iOS) ----
echo "📦 Building iOS IPA via EAS..."
eas build --platform ios --non-interactive --profile production

# ---- Stop backend ----
echo "🛑 Stopping backend..."
kill -9 $BACKEND_PID

echo "✅ Sovereign Auto Smart Build v6 Complete!"
echo "🌐 Backend endpoint: http://localhost:$PORT/api/hello"
