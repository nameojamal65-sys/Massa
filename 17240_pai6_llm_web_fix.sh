#!/data/data/com.termux/files/usr/bin/bash

echo "🌐 Fixing LLM + Web Layer"

pip install --upgrade openai fastapi uvicorn flask requests websocket-client >/dev/null 2>&1

echo "✅ LLM + Web Ready"
