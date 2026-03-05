#!/data/data/com.termux/files/usr/bin/bash
# ==================================================
# Sovereign Auto Smart Build v6 for Termux
# ✅ Fixes Node, NVM, PREFIX, Port conflicts, Expo token
# ==================================================

echo "🚀 Starting Sovereign Auto Smart Build v6..."

# -----------------------------
# 1️⃣ Unset conflicting PREFIX
# -----------------------------
unset PREFIX
echo "✅ PREFIX unset"

# -----------------------------
# 2️⃣ Load NVM
# -----------------------------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
  echo "✅ NVM loaded"
else
  echo "⚠️ NVM not found, installing..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
  \. "$NVM_DIR/nvm.sh"
fi

# -----------------------------
# 3️⃣ Install and use Node 18.17.1
# -----------------------------
nvm install 18.17.1
nvm use 18.17.1
echo "✅ Node.js v18.17.1 active"

# -----------------------------
# 4️⃣ Navigate to project folder
# -----------------------------
cd ~/sovereign_android_full || { echo "❌ Folder not found"; exit 1; }

# -----------------------------
# 5️⃣ Kill process on port 5000 if in use
# -----------------------------
if lsof -i :5000 &>/dev/null; then
  PID=$(lsof -t -i :5000)
  kill -9 $PID
  echo "✅ Port 5000 freed"
fi

# -----------------------------
# 6️⃣ Ensure main build script exists
# -----------------------------
if [ ! -f "sovereign_auto_full.sh" ]; then
  echo "❌ sovereign_auto_full.sh not found in project folder"
  exit 1
fi

# -----------------------------
# 7️⃣ Give execution permissions
# -----------------------------
chmod +x sovereign_auto_full.sh

# -----------------------------
# 8️⃣ Run the build
# -----------------------------
echo "📦 Running sovereign_auto_full.sh..."
./sovereign_auto_full.sh

echo "✅ Sovereign Auto Smart Build v6 Finished!"
