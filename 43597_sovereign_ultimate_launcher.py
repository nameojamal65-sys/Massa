#!/usr/bin/env python3
"""
🚀 Sovereign Ultimate AI – Integrated Capabilities Launcher
ملف رئيسي لتشغيل جميع الوحدات الذكية تلقائيًا داخل منظومة Sovereign
"""

import os
import subprocess
import threading
import time

# --- PATH TO SCRIPTS ---
SCRIPTS = {
    "system_watcher": "system_watcher.py",
    "self_updater": "self_updater.py",
    "data_analyzer": "intelligent_data_analyzer.py",
    "security_agent": "autonomous_security_agent.py",
    "ai_command_executor": "ai_command_executor.py",
    "report_center": "unified_report_center.py",
    "performance_optimizer": "autonomous_optimizer.py"
}

# --- CHECK AND CREATE PLACEHOLDER SCRIPTS IF MISSING ---
for name, path in SCRIPTS.items():
    if not os.path.exists(path):
        with open(path, "w") as f:
            f.write(f"# Placeholder for {name}\n")
            f.write("print('🚀 {} running...')\n".format(name))
        os.chmod(path, 0o755)

# --- FUNCTION TO RUN EACH SCRIPT IN THREAD ---
def run_script(script_path):
    try:
        subprocess.run(["python3", script_path])
    except Exception as e:
        print(f"❌ Error running {script_path}: {e}")

# --- LAUNCH ALL SCRIPTS CONCURRENTLY ---
threads = []
for script_name, script_path in SCRIPTS.items():
    t = threading.Thread(target=run_script, args=(script_path,))
    t.start()
    threads.append(t)
    print(f"✅ Launched {script_name}")

# --- OPTIONAL: KEEP THE LAUNCHER RUNNING ---
try:
    while True:
        time.sleep(5)
except KeyboardInterrupt:
    print("🛑 Stopping Sovereign Ultimate AI Launcher...")
