#!/usr/bin/env python3
import os
import shutil
import subprocess

print("❄️ Starting Sovereign Ultimate Freeze...")

# 1️⃣ مجلد العمل للفريز
frozen_dir = "sovereign_frozen_final"
if os.path.exists(frozen_dir):
    shutil.rmtree(frozen_dir)
os.makedirs(frozen_dir)

# 2️⃣ نسخ كل سكربتات النظام الأساسية
scripts = [
    "sovereign_hyper_system.py",
    "sovereign_legendary_autonomous.py",
    "sovereign_legendary_dashboard.py",
    "sovereign_ultimate_ai.py",
    # أضف أي سكربتات أساسية أخرى
]

for s in scripts:
    if os.path.exists(s):
        shutil.copy(s, frozen_dir)
        print(f"📂 Copied: {s}")

# 3️⃣ الانتقال لمجلد الفريز
os.chdir(frozen_dir)

# 4️⃣ منح صلاحيات تنفيذ
os.system("chmod +x *.py")

# 5️⃣ تثبيت PyInstaller لو غير مثبت
try:
    import PyInstaller
except ImportError:
    print("📦 Installing PyInstaller...")
    os.system("pip install --user pyinstaller")

# 6️⃣ بناء ملف تنفيذي واحد لكل سكربت (standalone binaries)
for s in scripts:
    script_name = os.path.basename(s)
    exe_name = script_name.replace(".py", "")
    print(f"🚀 Freezing {script_name} into executable...")
    os.system(f"pyinstaller --onefile --noconsole {script_name}")

# 7️⃣ إنشاء سكربت launcher لتشغيل جميع الملفات التنفيذية
with open("run_sovereign.sh", "w") as f:
    f.write("""#!/bin/bash
echo "🚀 Launching Sovereign Ultimate Frozen System..."
for exe in dist/*; do
    chmod +x "$exe"
    "$exe" &
done
wait
""")
os.system("chmod +x run_sovereign.sh")

print("🎉 Sovereign System is now fully frozen and ready to run!")
print("👉 Run './run_sovereign.sh' inside the 'sovereign_frozen_final' folder.")
