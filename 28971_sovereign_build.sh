#!/bin/bash
# ===============================
# 🔹 Sovereign One-Click Reset & Build
# ===============================

echo "🚀 Starting Sovereign Full Reset & Build..."

# 1️⃣ Unset conflicting environment variables
echo "💡 Unsetting PREFIX..."
unset PREFIX

# 2️⃣ Use correct Node & NPM versions
echo "💡 Using Node v24.13.0 and NPM 11.10.0..."
nvm install 24.13.0
nvm use 24.13.0

# 3️⃣ Clean old dependencies
echo "💡 Cleaning old node_modules and caches..."
cd ~/sovereign_android_full
rm -rf node_modules package-lock.json
npm cache clean --force

# 4️⃣ Reinstall dependencies
echo "💡 Installing project dependencies..."
npm install

# 5️⃣ Install/Update eas-cli
echo "💡 Installing latest eas-cli..."
npm install --save-dev eas-cli

# 6️⃣ Configure EAS Build
echo "💡 Configuring EAS Build..."
npx eas build:configure

# 7️⃣ Set environment to skip fingerprint issues
export EAS_SKIP_AUTO_FINGERPRINT=1

# 8️⃣ Suppress Expo Go warning (recommended for production)
export EAS_BUILD_NO_EXPO_GO_WARNING=true

# 9️⃣ Start production Android build
echo "💡 Starting Android build (production)..."
npx eas build -p android --profile production

echo "✅ One-Click Sovereign Build Script finished."
echo "Check build logs at your Expo dashboard for final status."
