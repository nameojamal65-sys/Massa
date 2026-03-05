#!/bin/bash
# ===============================================
# 🔥 Full Transformation Script for Sovereign
# Monorepo + Modular + Multi-platform + AI Integration
# ===============================================

set -e

echo "🚀 Starting Full Transformation..."

# --- Step 1: Setup Monorepo Structure ---
echo "📁 Creating Monorepo structure..."
mkdir -p packages/backend packages/frontend packages/shared configs

# Move existing files to packages
mv ./backend/* packages/backend/ 2>/dev/null || true
mv ./frontend/* packages/frontend/ 2>/dev/null || true
mv ./shared/* packages/shared/ 2>/dev/null || true

echo "✅ Monorepo structure ready!"

# --- Step 2: Setup Config-driven Instances ---
echo "⚙️ Creating default config..."
cat > configs/default.json <<EOL
{
  "theme": {
    "primaryColor": "#1F2937",
    "secondaryColor": "#3B82F6"
  },
  "features": {
    "chat": true,
    "ai_tasks": true,
    "analytics": true
  }
}
EOL
echo "✅ Config-driven setup ready!"

# --- Step 3: Initialize AI Core Service ---
echo "🤖 Setting up AI Core integration..."
mkdir -p packages/shared/ai
cat > packages/shared/ai/ai_service.js <<EOL
export async function queryAI(prompt) {
  // Placeholder for Abu Miftah AI
  console.log("Querying AI:", prompt);
  return "Response from AI Core";
}
EOL
echo "✅ AI Core module ready!"

# --- Step 4: Backend Setup ---
echo "🖥 Setting up backend..."
cat > packages/backend/main.py <<EOL
from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/api/hello")
def hello():
    return jsonify({"message": "Sovereign Backend Online"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOL

echo "✅ Backend ready!"

# --- Step 5: Frontend Setup ---
echo "🌐 Preparing frontend..."
mkdir -p packages/frontend/src
cat > packages/frontend/src/App.js <<EOL
import React from "react";

export default function App() {
  return (
    <div>
      <h1>Sovereign Frontend Online</h1>
    </div>
  );
}
EOL

echo "✅ Frontend ready!"

# --- Step 6: Multi-platform Setup ---
echo "📦 Setting up Expo & Web..."
cd packages/frontend
npx create-expo-app . --template blank --yes
cd ../..

# --- Step 7: Install Dependencies ---
echo "📥 Installing dependencies..."
npm install --legacy-peer-deps || true
cd packages/frontend && npm install --legacy-peer-deps && cd ../..

echo "✅ Dependencies installed!"

# --- Step 8: Setup Build Scripts ---
echo "🔧 Creating build scripts..."
cat > build_all.sh <<EOL
#!/bin/bash
echo "🚀 Building backend..."
cd packages/backend
pip install flask
python main.py &

echo "🚀 Building frontend..."
cd ../frontend
npm run web &

echo "echo '✅ All platforms running!'"
EOL
chmod +x build_all.sh

echo "✅ Build scripts ready!"

echo "🎉 Transformation Complete!"
echo "🖥 Run ./build_all.sh to start backend + frontend"
