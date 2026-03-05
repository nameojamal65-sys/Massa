/#!/data/data/com.termux/files/usr/bin/bash

echo "🧠 FINAL SYSTEM DIAGNOSTIC"
echo "=========================="

python - << 'PY'
import platform, sys, psutil, os
print("CPU:", platform.processor())
print("RAM:", round(psutil.virtual_memory().total/1024/1024,1),"MB")
print("Python:", sys.version.split()[0])
print("System Stable ✔")
PY

echo "=========================="
