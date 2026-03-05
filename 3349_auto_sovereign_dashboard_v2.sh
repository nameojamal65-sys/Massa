#!/bin/bash
# --- Fully Automatic Sovereign AI Dashboard Setup & Launch ---

DASHBOARD_DIR=~/sovereign_dashboard

# حذف أي مجلد قديم
if [ -d "$DASHBOARD_DIR" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_DIR"
fi

# إنشاء مشروع React + Vite جديد
echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@latest "$DASHBOARD_DIR" -- --template react --force

cd "$DASHBOARD_DIR" || exit

# تثبيت الاعتمادات
echo "🔹 Installing dependencies..."
npm install
npm install axios react-router-dom

# إنشاء ملف API تواصل مع Python AI
cat > src/sovereignAPI.js << EOL
import axios from "axios";

const BASE_URL = "http://127.0.0.1:5000";

export const callAI = async (capability, params) => {
  try {
    const res = await axios.post(\`\${BASE_URL}/run\`, { capability, params });
    return res.data;
  } catch (err) {
    return { error: err.message };
  }
};
EOL

# إنشاء صفحة رئيسية مع أزرار لكل Capability
cat > src/App.jsx << EOL
import { useState } from "react";
import { callAI } from "./sovereignAPI";

const CAPABILITIES = [
  "Data Collection",
  "Data Processing",
  "Analytics",
  "Dashboard",
  "AI Engine"
];

function App() {
  const [output, setOutput] = useState("");

  const handleClick = async (cap) => {
    const res = await callAI(cap, {});
    setOutput(JSON.stringify(res, null, 2));
  };

  return (
    <div style={{ padding: "2rem", fontFamily: "sans-serif" }}>
      <h1>Sovereign AI Dashboard</h1>
      <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
        {CAPABILITIES.map((cap) => (
          <button key={cap} onClick={() => handleClick(cap)}>
            {cap}
          </button>
        ))}
      </div>
      <pre style={{ marginTop: "2rem", background: "#eee", padding: "1rem" }}>
        {output}
      </pre>
    </div>
  );
}

export default App;
EOL

# تشغيل الـPython AI Server (يجب أن يكون موجود مسبقاً)
echo "🔹 Ensure your Sovereign AI Python server runs on port 5000"

# تشغيل المشروع
echo "🔹 Starting the React dashboard..."
npm run dev &

URL="http://127.0.0.1:5173"
if command -v xdg-open &> /dev/null; then
    xdg-open "$URL"
elif command -v am start &> /dev/null; then
    am start -a android.intent.action.VIEW -d "$URL"
fi

echo "✅ Dashboard should now be running at $URL"
