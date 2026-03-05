#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd /data/data/com.termux/files/home/sovereign_core
# shellcheck disable=SC1091
source .venv/bin/activate
python -m dev_agent.cli
