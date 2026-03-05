#!/usr/bin/env bash
echo "🚀 Launching PAI6 Sovereign Autonomous Core"
python3 core/kernel/engine.py &
uvicorn control.api.gateway:app --host 0.0.0.0 --port 8080