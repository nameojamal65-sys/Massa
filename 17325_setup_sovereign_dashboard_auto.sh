#!/bin/bash
# 🚀 Fully Automated Sovereign Dashboard Setup (React + Vite)

DASHBOARD_DIR=~/sovereign_dashboard
VITE_VERSION=latest

echo "🔹 Removing old dashboard directory if exists..."
rm -rf $DASHBOARD_DIR

echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@$VITE_VERSION $DASHBOARD_DIR -- --template react

cd $DASHBOARD_DIR || { echo "❌ Cannot enter dashboard directory"; exit 1; }

echo "🔹 Installing dependencies..."
npm install
npm install axios

echo "✅ Setup Complete!"
echo "💻 To run the dashboard now, type:"
echo "cd ~/sovereign_dashboard && npm run dev"
echo "🌐 Open the URL shown in the terminal (usually http://127.0.0.1:5173) in your browser"
