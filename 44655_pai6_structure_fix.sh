#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/sovereign_core"

echo "🛠 Fixing Structure..."

mkdir -p $BASE/{core,engine,modules,security,models,llm,api,web,video,logs,tmp,db}

find $BASE -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ Structure Rebuilt"
