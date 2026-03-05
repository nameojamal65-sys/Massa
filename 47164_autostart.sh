#!/usr/bin/env bash
set -e
export PYTHONUNBUFFERED=1
python -c "import flask, flask_socketio, psutil, PIL, yaml, cryptography" >/dev/null 2>&1 || pip install -r requirements.txt
echo "🚀 Platform running: http://127.0.0.1:8080"
python -m ui.app
