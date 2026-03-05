#!/data/data/com.termux/files/usr/bin/bash
# ───────────────────────────────────────────────
# Sovereign Full Auto Build Script for Termux
# Handles Node.js version, Expo/EAS CLI, and builds APK/IPA
# ───────────────────────────────────────────────

# ---------- إعداد المتغيرات ----------
RECOMMENDED_NODE="18.17.1"
EAS_CLI_VERSION="18.0.1"
EXPO_TOKEN="ضع_توكن_Expo_هنا"  # ضع توكن حسابك هنا

# ---------- دالة التحقق من أمر ----------
check_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "⚠️ $1 غير مثبت. سيتم التثبيت الآن."; return 1; }
  return 0
}

# ---------- Node.js ----------
NODE_VER=$(node -v 2>/dev/null | tr -d 'v')
if [ "$NODE_VER" != "$RECOMMENDED_NODE" ]; then
  echo "⚠️ إصدار Node.js الحالي $NODE_VER، الموصى به $RECOMMENDED_NODE"
  echo "🔧 تثبيت nvm وتغيير الإصدار..."
  check_command curl && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install $RECOMMENDED_NODE
  nvm use $RECOMMENDED_NODE
fi

# ---------- تثبيت npm packages الضرورية ----------
echo "📦 تثبيت npm packages اللازمة..."
check_command npm || pkg install nodejs -y
npm install -g eas-cli@$EAS_CLI_VERSION expo-cli

# ---------- تسجيل الدخول باستخدام توكن ----------
if [ -z "$EXPO_TOKEN" ]; then
  echo "⚠️ لم يتم وضع Expo token في المتغير. يجب وضعه قبل المتابعة!"
  exit 1
fi
export EXPO_TOKEN
echo "🔑 تسجيل الدخول إلى EAS باستخدام التوكن..."
eas whoami >/dev/null 2>&1 || eas login --token $EXPO_TOKEN

# ---------- إنشاء backend إذا لم يكن موجود ----------
PORT=5000
if lsof -i:$PORT >/dev/null; then
  echo "⚠️ المنفذ $PORT مستخدم. إيقاف أي عملية تعمل عليه..."
  kill -9 $(lsof -ti:$PORT)
fi

if [ ! -f "./backend/main.py" ]; then
  echo "⚠️ لم يتم العثور على backend. سيتم إنشاء dummy backend..."
  mkdir -p backend
  cat <<EOL > backend/main.py
from flask import Flask
app = Flask(__name__)

@app.route('/api/hello')
def hello():
    return {"status":"ok","message":"Sovereign API ready"}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL
fi
echo "🖥 تشغيل backend..."
python3 backend/main.py &
BACKEND_PID=$!

# ---------- تهيئة مشروع Expo ----------
if [ ! -f "eas.json" ]; then
  echo "⚙️ تهيئة مشروع EAS..."
  eas init --non-interactive
fi

# ---------- بناء APK وIPA ----------
echo "📦 بدء البناء..."
eas build --platform android --non-interactive --profile production
eas build --platform ios --non-interactive --profile production

# ---------- إيقاف backend ----------
echo "🛑 إيقاف backend..."
kill -9 $BACKEND_PID

echo "✅ عملية البناء الكاملة اكتملت!"
