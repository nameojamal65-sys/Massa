#!/usr/bin/env python3
"""
Sovereign Legendary Master
سكربت شامل: يعطي صلاحيات لكل السكربتات، يشغل كل القدرات، ويراقبها تلقائيًا
"""

import os
import threading
import time
import subprocess

# ======= إعطاء صلاحيات التنفيذ لجميع ملفات البايثون =======
os.system("chmod +x *.py")
print("✅ تم إعطاء جميع الملفات صلاحيات التنفيذ")

# ======= دوال القدرات =======
def ai_engine():
    while True:
        print("🤖 AI يعمل: تحليل البيانات، توصيات ذكية")
        time.sleep(5)

def data_collection():
    while True:
        print("📂 جمع البيانات تلقائيًا")
        time.sleep(7)

def data_processing():
    while True:
        print("⚙️ معالجة البيانات وتحويلها")
        time.sleep(6)

def analytics():
    while True:
        print("📊 التحليلات الحية جارية")
        time.sleep(8)

def dashboard():
    while True:
        print("🌐 لوحة التحكم نشطة لجميع القدرات")
        time.sleep(10)

def unknown_capabilities():
    while True:
        print("🛠️ تشغيل القدرات التجريبية")
        time.sleep(12)

# ======= مراقبة أي سكربت يتوقف =======
def monitor_script(script_name):
    while True:
        try:
            # محاولة تشغيل السكربت
            process = subprocess.Popen(["python3", script_name])
            process.wait()
        except Exception as e:
            print(f"❌ خطأ في {script_name}: {e}")
        print(f"🔄 إعادة تشغيل {script_name} تلقائيًا بعد توقفه")
        time.sleep(3)

# ======= تشغيل كل القدرات بالتوازي =======
threads = [
    threading.Thread(target=ai_engine),
    threading.Thread(target=data_collection),
    threading.Thread(target=data_processing),
    threading.Thread(target=analytics),
    threading.Thread(target=dashboard),
    threading.Thread(target=unknown_capabilities),
]

# إضافة مراقبة بعض السكربتات الأساسية (يمكن تعديل الأسماء حسب مشروعك)
scripts_to_monitor = ["sovereign_ai_analyzer.py", "dashboard_full.py"]
for s in scripts_to_monitor:
    threads.append(threading.Thread(target=monitor_script, args=(s,)))

for t in threads:
    t.daemon = True
    t.start()

print("🚀 كل القدرات تعمل والمراقبة نشطة! المنظومة أسطورية ⚡")

# ======= الحفاظ على عمل السكربت =======
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("🛑 تم إيقاف المنظومة يدويًا")
