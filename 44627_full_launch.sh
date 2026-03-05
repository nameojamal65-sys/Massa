#!/bin/bash
# ===============================
# 🚀 PAI6 Full Auto Builder Launch
# ===============================

echo "⚙️ Bootstrapping PAI6 Builder Environment..."

# 1️⃣ اعطاء صلاحيات لكل الملفات المهمة
chmod +x $HOME/server.js
chmod +x $HOME/dashboard.py
chmod +x $HOME/build_all.sh

# 2️⃣ تثبيت مكتبات Node.js وPython
echo "📦 Installing Node.js packages..."
cd $HOME
npm init -y >/dev/null 2>&1
npm install express >/dev/null 2>&1

echo "📦 Installing Python packages..."
pip install --upgrade pip >/dev/null 2>&1
pip install flask >/dev/null 2>&1

# 3️⃣ بناء المشاريع باستخدام build_all.sh
echo "🛠️ Building all projects..."
bash $HOME/build_all.sh

# 4️⃣ تشغيل Node.js Server
echo "⚡ Starting Node.js server..."
nohup node $HOME/server.js >/dev/null 2>&1 &
NODE_PID=$!
echo "✅ Node.js running with PID $NODE_PID"

# 5️⃣ تشغيل Flask Dashboard
echo "⚡ Starting Flask dashboard..."
nohup python3 $HOME/dashboard.py >/dev/null 2>&1 &
FLASK_PID=$!
echo "✅ Flask running with PID $FLASK_PID"

echo "🎯 PAI6 Builder Fully Launched!"
echo "🌐 Node.js Builder: http://localhost:3000"
echo "🌐 Flask Dashboard: http://localhost:8080"x
