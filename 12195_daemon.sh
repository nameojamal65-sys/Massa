#!/bin/bash
nohup python3 app.py > legendary.log 2>&1 &
echo $! > legendary.pid
echo "✅ Legendary running in background"
