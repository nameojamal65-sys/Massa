#!/data/data/com.termux/files/usr/bin/bash
# =============================
# 🚀 Legendary Full Hyper-Fast Wi-Fi Dashboard Launcher
# =============================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
AGENT_FILE="$SYSTEM_DIR/ai_agent_online.py"
LOG_FILE="$SYSTEM_DIR/ai_agent.log"
FRONTEND_LOG="$SYSTEM_DIR/frontend.log"

PORT=9000
FRONTEND_PORT=3000

echo "⏳ تحضير المنظومة Hyper-Fast كاملة على Wi-Fi..."

# البحث عن بورت فارغ بسرعة
while lsof -i tcp:$PORT >/dev/null 2>&1; do
    PORT=$((PORT+1))
done
while lsof -i tcp:$FRONTEND_PORT >/dev/null 2>&1; do
    FRONTEND_PORT=$((FRONTEND_PORT+1))
done

echo "✅ البورت $PORT جاهز للإيجنت"
echo "✅ البورت $FRONTEND_PORT جاهز للفرونت اند"

# قتل أي عملية بايثون عالقة
pkill -f python3 >/dev/null 2>&1

# تشغيل الإيجنت في الخلفية
nohup python3 -u $AGENT_FILE $PORT > $LOG_FILE 2>&1 &
disown
echo "🚀 AI Agent يعمل الآن على localhost:$PORT في الخلفية"

# إنشاء واجهة React Dashboard تلقائيًا
FRONTEND_DIR="$SYSTEM_DIR/frontend_dashboard"
mkdir -p $FRONTEND_DIR

cat > $FRONTEND_DIR/App.js << 'EOF'
import React, { useState, useEffect } from "react";
import io from "socket.io-client";
import "./App.css";

const socket = io("http://localhost:9000");

export default function Dashboard() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  useEffect(() => {
    socket.on("chat message", (msg) => {
      setMessages((prev) => [...prev, msg]);
    });
    return () => socket.off("chat message");
  }, []);

  const sendMessage = () => {
    if (input.trim() === "") return;
    socket.emit("chat message", input);
    setInput("");
  };

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>🚀 Legendary Hyper-Fast Dashboard</h1>
      </header>

      <main>
        <div className="controls">
          <button onClick={() => alert("زر 1 ضغطت!")}>زر 1</button>
          <button onClick={() => alert("زر 2 ضغطت!")}>زر 2</button>
          <button onClick={() => alert("زر 3 ضغطت!")}>زر 3</button>
        </div>

        <div className="chat-box">
          <h2>💬 شات المنظومة</h2>
          <div className="messages">
            {messages.map((msg, idx) => (
              <div key={idx} className="message">
                {msg}
              </div>
            ))}
          </div>
          <div className="input-box">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="اكتب رسالة..."
            />
            <button onClick={sendMessage}>إرسال</button>
          </div>
        </div>
      </main>
    </div>
  );
}
EOF

cat > $FRONTEND_DIR/App.css << 'EOF'
.dashboard {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #0ff, #00a);
  color: #fff;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.dashboard-header {
  width: 100%;
  background-color: rgba(0,0,0,0.6);
  padding: 20px;
  text-align: center;
  font-size: 2rem;
  box-shadow: 0 4px 10px rgba(0,0,0,0.5);
}
.controls { margin: 20px 0; }
.controls button {
  margin: 0 10px; padding: 12px 25px;
  background: #0ff; color: #121212; font-weight: bold;
  border: none; border-radius: 12px; cursor: pointer;
  transition: 0.3s;
}
.controls button:hover { background: #0aa; }
.chat-box {
  width: 90%; max-width: 600px;
  background: rgba(0,0,0,0.5);
  padding: 20px; border-radius: 15px;
}
.messages {
  max-height: 300px; overflow-y: auto;
  margin-bottom: 10px; border: 1px solid #0ff;
  padding: 10px; border-radius: 10px;
}
.message { padding: 8px; margin-bottom: 5px; background: rgba(255,255,255,0.1); border-radius: 5px; }
.input-box { display: flex; gap: 10px; }
.input-box input { flex: 1; padding: 10px; border-radius: 8px; border: none; }
.input-box button { padding: 10px 20px; border-radius: 8px; border: none; background: #0ff; color: #121212; font-weight: bold; cursor: pointer; }
.input-box button:hover { background: #0aa; }
EOF

# تشغيل React Dashboard
cd $FRONTEND_DIR
nohup npx react-scripts start > $FRONTEND_LOG 2>&1 &
disown

echo "🚀 Frontend Dashboard فخم يعمل الآن على http://localhost:$FRONTEND_PORT"
echo "🔹 متابعة اللوغ: tail -f $LOG_FILE"
echo "🔹 متابعة Frontend لوغ: tail -f $FRONTEND_LOG"
