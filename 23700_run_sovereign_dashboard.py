#!/usr/bin/env python3
import os
import subprocess
import sys
import time
import platform
import webbrowser

# --- إعداد المسار لمشروع الداشبورد ---
DASHBOARD_PATH = os.path.expanduser("~/sovereign_dashboard")  # ضع هنا مجلد المشروع

# --- تشغيل المشروع ---
def run_dashboard():
    if not os.path.exists(DASHBOARD_PATH):
        print(f"❌ مجلد المشروع غير موجود: {DASHBOARD_PATH}")
        sys.exit(1)

    os.chdir(DASHBOARD_PATH)
    print("⚡ تشغيل Vite React Dashboard...")

    # تثبيت الحزم لو لم تكن مثبتة
    if not os.path.exists(os.path.join(DASHBOARD_PATH, "node_modules")):
        print("📦 تثبيت الحزم المطلوبة...")
        subprocess.run(["npm", "install"], check=True)

    # تشغيل السيرفر في subprocess
    print("🚀 بدء السيرفر...")
    proc = subprocess.Popen(["npm", "run", "dev"])

    # الانتظار قليلًا قبل فتح المتصفح
    time.sleep(3)

    # فتح الرابط في المتصفح
    url = "http://127.0.0.1:5173/"
    print(f"🌐 فتح المتصفح على {url} ...")
    webbrowser.open(url)

    print("✅ الداشبورد قيد التشغيل، اضغط Ctrl+C لإيقافه.")
    try:
        proc.wait()
    except KeyboardInterrupt:
        print("\n🛑 إيقاف السيرفر...")
        proc.terminate()
        sys.exit(0)

if __name__ == "__main__":
    run_dashboard()

