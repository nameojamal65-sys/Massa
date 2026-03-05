#!/usr/bin/env python3
import os
import subprocess
import time

# قائمة السكربتات التي تريد تشغيلها
scripts = [
    "sovereign_system_monitor.py",
    "sovereign_auto_installer.py",
    "sovereign_file_organizer.py",
    "sovereign_ai_refactor.py",
    "sovereign_dashboard_enhancer.py"
]

# اعطاء صلاحيات تشغيل لكل سكربت
for script in scripts:
    if os.path.exists(script):
        os.chmod(script, 0o755)
        print(f"✅ {script} is now executable")
    else:
        print(f"⚠️ {script} not found!")

# تشغيل السكربتات في الخلفية
processes = []
for script in scripts:
    if os.path.exists(script):
        p = subprocess.Popen(["python3", script])
        processes.append(p)
        print(f"🚀 {script} launched")
        time.sleep(1)  # للتأكد من بدء كل سكربت قبل التالي

print("\n🌐 All Sovereign scripts are running!")
print("Use Ctrl+C to stop this master launcher, scripts will remain running in background if started as daemon.")
