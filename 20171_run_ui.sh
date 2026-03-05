#!/usr/bin/env bash
echo "🌐 Launching Sovereign UI -> http://127.0.0.1:9191"
uvicorn api.main:app --host 0.0.0.0 --port 9191
