#!/usr/bin/env bash
set -e
mkdir -p /app/logs
python3 /app/core/core.py > /app/logs/core.log 2>&1 &
exec python3 /app/ui/server.py
