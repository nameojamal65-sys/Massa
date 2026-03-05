#!/bin/bash
echo "🚀 Launching Sovereign Frozen System..."
for script in *.py; do
    python3 "$script" &
done
wait
