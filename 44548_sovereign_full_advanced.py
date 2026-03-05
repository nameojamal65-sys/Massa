#!/usr/bin/env python3
import os
import subprocess
import sys
import time
import webbrowser
from threading import Thread

AI_SCRIPT = os.path.expanduser("~/sovereign_ai_v3.py")
DASHBOARD_PATH = os.path.expanduser("~/sovereign_dashboard")  # مجلد React + Vite
DASHBOARD_URL = "http://127.0.0.1:5173/"

def start_ai():
    while True:
        try:
            print("🤖 تشغيل Sovereign AI System...")
            ai_proc = subprocess.Popen(["python3", AI_SCRIPT])
            ai_proc.wait()
            print("⚠️ AI توقف! إعادة التشغيل بعد 3 ثوانٍ...")
            time.sleep(3)
        except KeyboardInterrupt:
            print("🛑 إيقاف AI...")
            ai_proc.terminate()
            break

def start_dashboard():
    os.chdir(DASHBOARD_PATH)
    if not os.path.exists(os.path.join(DASHBOARD_PATH, "node_modules")):
        print("📦 تثبيت الحزم المطلوبة...")
        subprocess.run(["npm", "install"], check=True)

    while True:
        try:
            print("⚡ تشغيل React + Vite Dashboard...")
            dash_proc = subprocess.Popen(["npm", "run", "dev"])
            time.sleep(3)
            webbrowser.open(DASHBOARD_URL)
            dash_proc.wait()
            print("⚠️ Dashboard توقف! إعادة التشغيل بعد 3 ثوانٍ...")
            time.sleep(3)
        except KeyboardInterrupt:
            print("🛑 إيقاف Dashboard...")
            dash_proc.terminate()
            break

def main():
    ai_thread = Thread(target=start_ai, daemon=True)
    dash_thread = Thread(target=start_dashboard, daemon=True)
    ai_thread.start()
    dash_thread.start()
    
    print("✅ جميع الأنظمة تعمل الآن! اضغط Ctrl+C لإيقافها.")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 إيقاف جميع الأنظمة...")
        sys.exit(0)

if __name__ == "__main__":
    main()
