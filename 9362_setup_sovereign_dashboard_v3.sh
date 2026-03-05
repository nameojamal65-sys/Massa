#!/bin/bash
# 🚀 Setup Sovereign Dashboard React (Termux friendly)

DASHBOARD_DIR=~/sovereign_dashboard

echo "🔹 Removing old dashboard directory if exists..."
rm -rf $DASHBOARD_DIR

echo "🔹 Creating new Sovereign Dashboard with Vite + React..."
npm create vite@$VITE_VERSION $DASHBOARD_DIR -- --template react

cd $DASHBOARD_DIR || exit

echo "🔹 Installing dependencies..."
npm install
npm install axios

echo "✅ Setup Complete!"
echo "💻 To run the dashboard:"
echo "cd ~/sovereign_dashboard"
echo "npm run dev"
