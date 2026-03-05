#!/bin/bash
echo "🔹 Setting up Sovereign Real AI Dashboard..."

# مسار المشروع
DASHBOARD_PATH=~/sovereign_dashboard

# إزالة أي Dashboard قديم
if [ -d "$DASHBOARD_PATH" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_PATH"
fi

# إنشاء مشروع React + Vite جديد
echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@latest "$DASHBOARD_PATH" -- --template react

cd "$DASHBOARD_PATH" || exit

# تثبيت dependencies
npm install
npm install axios  # للتواصل مع بايثون

# إنشاء ملف للتواصل مع بايثون AI
cat > src/api.js <<EOL
import axios from "axios";

const API_BASE = "http://127.0.0.1:5000";  // سيرفر بايثون

export const sendTaskToAI = async (task) => {
  try {
    const response = await axios.post(\`\${API_BASE}/ai_task\`, { task });
    return response.data;
  } catch (error) {
    return { error: error.message };
  }
};
EOL

# إنشاء صفحة رئيسية تربط الواجهة بالذكاء الاصطناعي
cat > src/App.jsx <<EOL
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
EOL

echo "✅ Sovereign Dashboard Setup Complete!"
echo "Run: cd ~/sovereign_dashboard && npm run dev to start React Dashboard"
