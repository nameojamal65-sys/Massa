#!/bin/bash
# --- Sovereign AI Full Setup & Launch (Python + React) ---

DASHBOARD_DIR=~/sovereign_dashboard
PY_SERVER_FILE=~/sovereign_ai_server.py

# 1️⃣ حذف أي مجلد قديم للداشبورد
if [ -d "$DASHBOARD_DIR" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_DIR"
fi

# 2️⃣ إنشاء مشروع React + Vite جديد
echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@latest "$DASHBOARD_DIR" -- --template react --force

cd "$DASHBOARD_DIR" || exit

# 3️⃣ تثبيت الاعتمادات
echo "🔹 Installing dependencies..."
npm install
npm install axios react-router-dom

# 4️⃣ إنشاء API تواصل مع Python
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

# 5️⃣ إنشاء الصفحة الرئيسية مع أزرار لكل Capability
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

# 6️⃣ إنشاء Python AI Server مدمج
cat > $PY_SERVER_FILE << EOL
from flask import Flask, request, jsonify
import threading, time

app = Flask(__name__)

# Capabilities dummy responses
CAPS = {
    "Data Collection": {"status": "collecting data..."},
    "Data Processing": {"status": "processing data..."},
    "Analytics": {"status": "analyzing..."},
    "Dashboard": {"status": "dashboard ready"},
    "AI Engine": {"status": "AI engine operational"}
}

@app.route("/run", methods=["POST"])
def run_capability():
    data = request.json
    cap = data.get("capability", "Unknown")
    params = data.get("params", {})
    # simulate processing time
    time.sleep(1)
    return jsonify(CAPS.get(cap, {"status": "Unknown capability"}))

def start_server():
    app.run(port=5000)

# Run server in background
threading.Thread(target=start_server, daemon=True).start()
print("✅ Sovereign AI Python Server running on port 5000")

# Keep script alive
while True:
    time.sleep(60)
EOL

# 7️⃣ تشغيل Python Server في الخلفية
echo "🔹 Starting Python AI Server..."
python3 $PY_SERVER_FILE &

# 8️⃣ تشغيل React Dashboard
echo "🔹 Starting React Dashboard..."
npm run dev &

# فتح المتصفح تلقائياً
URL="http://127.0.0.1:5173"
if command -v xdg-open &> /dev/null; then
    xdg-open "$URL"
elif command -v am start &> /dev/null; then
    am start -a android.intent.action.VIEW -d "$URL"
fi

echo "✅ Dashboard should now be running at $URL"
echo "🔹 Python AI server on port 5000"
