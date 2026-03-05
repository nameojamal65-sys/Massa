#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home
source .venv/bin/activate

exec uvicorn app.main:app --host 127.0.0.1 --port 9100
