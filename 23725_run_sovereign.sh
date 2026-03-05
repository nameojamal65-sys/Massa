#!/bin/bash
echo "🚀 Launching Sovereign Ultimate Frozen System..."
for exe in dist/*; do
    chmod +x "$exe"
    "$exe" &
done
wait
