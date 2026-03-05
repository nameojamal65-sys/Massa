#!/data/data/com.termux/files/usr/bin/bash
# 🚀 Sovereign Auto Full Build with Abu Mftah Monitoring

echo "🚀 بدء Sovereign Auto Full Build..."

# --- Node.js Version Setup ---
RECOMMENDED_NODE="18.17.1"
CURRENT_NODE=$(node -v 2>/dev/null | tr -d 'v')

if [ "$CURRENT_NODE" != "$RECOMMENDED_NODE" ]; then
    echo "⚠️ Node.js الحالي $CURRENT_NODE، مطلوب $RECOMMENDED_NODE"
    echo "🔧 تثبيت Node.js الصحيح عبر nvm..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install $RECOMMENDED_NODE
    nvm use $RECOMMENDED_NODE
fi

echo "✅ Node.js مضبوط على الإصدار $RECOMMENDED_NODE"

# --- تثبيت الحزم اللازمة ---
echo "📦 تثبيت npm packages..."
npm install --legacy-peer-deps

# --- تحديث React & React Native ---
echo "⚠️ تحديث React & React Native..."
npx react-native upgrade

# --- إعداد Backend مع Abu Mftah ---
BACKEND_PORT=5000
echo "🖥 تشغيل backend على المنفذ $BACKEND_PORT..."
if lsof -i:$BACKEND_PORT >/dev/null; then
    echo "⚠️ المنفذ $BACKEND_PORT مشغول، سيتم تغييره إلى $((BACKEND_PORT+1))"
    BACKEND_PORT=$((BACKEND_PORT+1))
fi

export BACKEND_PORT
python3 -m flask run --host=0.0.0.0 --port=$BACKEND_PORT &

# --- Abu Mftah Monitoring ---
echo "🤖 تفعيل Abu Mftah لمراقبة البناء..."
# هنا يمكن إضافة أي أوامر مراقبة ذكية خاصة بك

# --- بناء APK عبر EAS ---
echo "📦 بناء Android APK عبر EAS..."
# تأكد أن لديك Expo token مضبوط في ENV:
# export EXPO_TOKEN="ضع_توكن_Expo_هنا"
eas build --platform android --non-interactive --profile production

echo "✅ Build Complete!"
echo "🌐 Backend endpoint: http://localhost:$BACKEND_PORT/api/hello"
