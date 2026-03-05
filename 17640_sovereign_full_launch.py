#!/usr/bin/env python3
import os
import subprocess
import sys
import time
import webbrowser

# --- إعداد المسارات ---
AI_SCRIPT = os.path.expanduser("~/sovereign_ai_v3.py")
DASHBOARD_PATH = os.path.expanduser("~/sovereign_dashboard")  # مجلد مشروع React + Vite

# --- وظائف مساعدة ---
def run_ai():
    if not os.path.exists(AI_SCRIPT):
        print(f"❌ ملف AI غير موجود: {AI_SCRIPT}")
        sys.exit(1)
    print("🤖 تشغيل Sovereign AI System...")
    ai_proc = subprocess.Popen(["python3", AI_SCRIPT])
    time.sleep(2)  # إعطاء وقت لبدء النظام
    return ai_proc

def run_dashboard():
    if not os.path.exists(DASHBOARD_PATH):
        print(f"❌ مجلد الداشبورد غير موجود: {DASHBOARD_PATH}")
        sys.exit(1)

    os.chdir(DASHBOARD_PATH)
    print("⚡ تشغيل React + Vite Dashboard...")

    # تثبيت الحزم إذا لم تكن موجودة
    if not os.path.exists(os.path.join(DASHBOARD_PATH, "node_modules")):
        print("📦 تثبيت الحزم المطلوبة...")
        subprocess.run(["npm", "install"], check=True)

    # تشغيل السيرفر
    dash_proc = subprocess.Popen(["npm", "run", "dev"])
    time.sleep(3)  # إعطاء وقت للبدء

    # فتح الرابط في المتصفح
    url = "http://127.0.0.1:5173/"
    print(f"🌐 فتح المتصفح على {url} ...")
    webbrowser.open(url)

    return dash_proc

# --- Main ---
if __name__ == "__main__":
    try:
        ai_proc = run_ai()
        dash_proc = run_dashboard()
        print("✅ جميع الأنظمة قيد التشغيل! اضغط Ctrl+C لإيقافها.")
        # الانتظار على أي من العمليات
        ai_proc.wait()
        dash_proc.wait()
    except KeyboardInterrupt:
        print("\n🛑 إيقاف جميع الأنظمة...")
        ai_proc.terminate()
        dash_proc.terminate()
        sys.exit(0)
