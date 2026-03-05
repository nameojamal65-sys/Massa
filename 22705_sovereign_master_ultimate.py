#!/usr/bin/env python3
import os
import subprocess
import threading
import time

# ==========================
# قائمة السكربتات التي تريد تشغيلها ومراقبتها
# ==========================
scripts = [
    "sovereign_system_monitor.py",
    "sovereign_auto_installer.py",
    "sovereign_file_organizer.py",
    "sovereign_ai_refactor.py",
    "sovereign_dashboard_enhancer.py"
]

# ==========================
# وظيفة تشغيل ومراقبة سكربت
# ==========================
def run_script(script_name):
    while True:
        if os.path.exists(script_name):
            try:
                print(f"🚀 Launching {script_name} ...")
                process = subprocess.Popen(["python3", script_name])
                process.wait()
                print(f"⚠️ {script_name} stopped unexpectedly, restarting in 3s...")
                time.sleep(3)
            except Exception as e:
                print(f"❌ Error running {script_name}: {e}")
                time.sleep(5)
        else:
            print(f"⚠️ {script_name} not found, skipping...")
            break

# ==========================
# اعطاء صلاحيات تنفيذ لكل سكربت
# ==========================
for script in scripts:
    if os.path.exists(script):
        os.chmod(script, 0o755)
        print(f"✅ {script} is now executable")
    else:
        print(f"⚠️ {script} not found!")

# ==========================
# تشغيل كل السكربتات في Threads
# ==========================
threads = []
for script in scripts:
    t = threading.Thread(target=run_script, args=(script,), daemon=True)
    t.start()
    threads.append(t)
    time.sleep(1)  # لتخفيف الضغط على النظام

print("\n🌐 Ultimate Sovereign Launcher is running all scripts!")
print("🛠 Monitoring active... Press Ctrl+C to stop this launcher (threads will exit).")

# إبقاء البرنامج الرئيسي يعمل
try:
    while True:
        time.sleep(5)
except KeyboardInterrupt:
    print("\n🛑 Stopping Ultimate Launcher. All threads will exit.")
