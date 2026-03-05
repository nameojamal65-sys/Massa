#!/bin/bash
# 🚀 Setup Sovereign Dashboard React

DASHBOARD_DIR=~/sovereign_dashboard

echo "🔹 Removing old dashboard directory if exists..."
rm -rf $DASHBOARD_DIR

echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@$VITE_VERSION $DASHBOARD_DIR -- --template react

cd $DASHBOARD_DIR || exit

echo "🔹 Installing dependencies..."
npm install
npm install axios

# --- api.js ---
cat > src/api.js << 'EOF'
import axios from "axios";
const API_BASE = "http://127.0.0.1:5000";
export const sendTaskToAI = async (task) => {
  try {
    const response = await axios.post(`${API_BASE}/ai_task`, { task });
    return response.data;
  } catch (error) {
    return { error: error.message };
  }
};
EOF

# --- App.jsx ---
cat > src/App.jsx << 'EOF'
import { useState } from "react";
import { sendTaskToAI } from "./api";

function App() {
  const [task, setTask] = useState("");
  const [result, setResult] = useState("");

  const handleSubmit = async () => {
    const res = await sendTaskToAI(task);
    setResult(res.output || JSON.stringify(res));
  };

  return (
    <div style={{ padding: 20 }}>
      <h1>Sovereign AI Dashboard</h1>
      <input
        type="text"
        value={task}
        onChange={(e) => setTask(e.target.value)}
        placeholder="Enter AI Task..."
        style={{ width: "400px", padding: "5px" }}
      />
      <button onClick={handleSubmit} style={{ marginLeft: 10, padding: "5px 10px" }}>
        Send to AI
      </button>
      <pre style={{ marginTop: 20, background: "#f0f0f0", padding: 10 }}>{result}</pre>
    </div>
  );
}

export default App;
EOF

echo "✅ Setup Complete!"
echo "💻 To run the dashboard:"
echo "cd ~/sovereign_dashboard"
echo "npm run dev"
