#!/data/data/com.termux/files/usr/bin/bash
# =========================================
# 🚀 Legendary Dashboard Hyper-Fast Frontend Launcher
# =========================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
FRONTEND_DIR="$SYSTEM_DIR/frontend"
LOG_FILE="$SYSTEM_DIR/frontend.log"
PORT=3000

echo "⏳ تحضير المنظومة Hyper-Fast للواجهة..."
if ! command -v npm >/dev/null 2>&1; then
    echo "📦 npm غير مثبت! قم بتثبيت Node.js أولاً: pkg install nodejs"
    exit 1
fi

# إذا كان هناك عملية React شغالة، اغلقها
pkill -f "react-scripts start" >/dev/null 2>&1

# إنشاء مجلد frontend إذا لم يكن موجود
mkdir -p $FRONTEND_DIR

# إنشاء ملفات React الأساسية
cat > $FRONTEND_DIR/package.json << 'EOF'
{
  "name": "legendary-dashboard",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  }
}
EOF

mkdir -p $FRONTEND_DIR/public $FRONTEND_DIR/src/components

cat > $FRONTEND_DIR/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Legendary Dashboard</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
EOF

cat > $FRONTEND_DIR/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles.css';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
EOF

cat > $FRONTEND_DIR/src/App.js << 'EOF'
import React from 'react';
import ChatBox from './components/ChatBox';
import DashboardPanel from './components/DashboardPanel';
import ControlButtons from './components/ControlButtons';

function App() {
  return (
    <div className="app-container">
      <h1>🚀 Legendary Dashboard</h1>
      <DashboardPanel />
      <ControlButtons />
      <ChatBox />
    </div>
  );
}

export default App;
EOF

cat > $FRONTEND_DIR/src/components/DashboardPanel.js << 'EOF'
import React from 'react';

function DashboardPanel() {
  return (
    <div className="dashboard-panel">
      <h2>📊 البيانات الحية</h2>
      <div className="data-grid">
        <div className="data-card">CPU: 15%</div>
        <div className="data-card">RAM: 60%</div>
        <div className="data-card">Users Online: 5</div>
        <div className="data-card">Requests: 120</div>
      </div>
    </div>
  );
}

export default DashboardPanel;
EOF

cat > $FRONTEND_DIR/src/components/ControlButtons.js << 'EOF'
import React from 'react';

function ControlButtons() {
  return (
    <div className="control-buttons">
      <button className="btn start">▶ تشغيل الإيجنت</button>
      <button className="btn stop">⏹ إيقاف الإيجنت</button>
      <button className="btn refresh">🔄 تحديث البيانات</button>
    </div>
  );
}

export default ControlButtons;
EOF

cat > $FRONTEND_DIR/src/components/ChatBox.js << 'EOF'
import React, { useState } from 'react';

function ChatBox() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');

  const sendMessage = () => {
    if (!input.trim()) return;
    setMessages([...messages, { text: input, sender: 'You' }]);
    setInput('');
  };

  return (
    <div className="chat-box">
      <h2>💬 Chat</h2>
      <div className="messages">
        {messages.map((msg, idx) => (
          <div key={idx} className={`message ${msg.sender}`}>
            <strong>{msg.sender}: </strong> {msg.text}
          </div>
        ))}
      </div>
      <input
        type="text"
        placeholder="اكتب رسالتك..."
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
      />
      <button onClick={sendMessage}>إرسال</button>
    </div>
  );
}

export default ChatBox;
EOF

cat > $FRONTEND_DIR/src/styles.css << 'EOF'
body {
  margin: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: #1a1a2e;
  color: #fff;
}

.app-container {
  max-width: 1200px;
  margin: auto;
  padding: 20px;
}

h1, h2 {
  text-align: center;
  color: #fca311;
}

.dashboard-panel {
  background: #162447;
  padding: 15px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.data-grid {
  display: flex;
  gap: 10px;
  justify-content: center;
  flex-wrap: wrap;
}

.data-card {
  background: #1f4068;
  padding: 20px;
  border-radius: 8px;
  width: 150px;
  text-align: center;
  font-weight: bold;
}

.control-buttons {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 20px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
  font-weight: bold;
}

.btn.start { background: #06d6a0; color: #000; }
.btn.stop { background: #ef476f; color: #fff; }
.btn.refresh { background: #ffd166; color: #000; }

.chat-box {
  background: #1f4068;
  padding: 15px;
  border-radius: 10px;
}

.messages {
  max-height: 200px;
  overflow-y: auto;
  margin-bottom: 10px;
}

.message {
  padding: 5px;
}

.message.You { text-align: right; color: #ffd166; }
EOF

# تثبيت الحزم
echo "⏳ تثبيت الحزم اللازمة..."
cd $FRONTEND_DIR
npm install

# تشغيل React frontend
echo "🚀 تشغيل واجهة Dashboard الفخمة على http://localhost:$PORT"
npm start
