#!/bin/bash
# ========================================
# 👑 PAI6 — Launch All Builder Services
# ========================================

echo "🚀 Launching PAI6 Builder Services..."

# 1️⃣ تأكد من الصلاحيات
bash $HOME/set_permissions.sh

# 2️⃣ شغّل Node.js Server
echo "⚙️ Starting Node.js Server (server.js)..."
node $HOME/server.js &
NODE_PID=$!
echo "✅ Node.js running with PID $NODE_PID"

# 3️⃣ شغّل Flask Dashboard
echo "⚙️ Starting Flask Dashboard (dashboard.py)..."
python3 $HOME/dashboard.py &
FLASK_PID=$!
echo "✅ Flask running with PID $FLASK_PID"

# 4️⃣ تأكد أن كل شيء شغّال
echo "🎯 PAI6 Builder Services Launched Successfully!"
echo "Node.js PID: $NODE_PID"
echo "Flask PID: $FLASK_PID"

echo "🌐 Access Node.js Builder: http://localhost:3000"
echo "🌐 Access Flask Dashboard: http://localhost:8080"
