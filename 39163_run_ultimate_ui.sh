#!/usr/bin/env bash
echo "🌐 Launching PAI6 Ultimate Dashboard -> http://127.0.0.1:9393"
uvicorn api.main:app --host 0.0.0.0 --port 9393
