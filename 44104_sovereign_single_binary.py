#!/usr/bin/env python3
import os
import shutil
import subprocess

print("❄️ Starting Sovereign Ultimate Single Binary Freeze...")

# 1️⃣ مجلد مؤقت لتجميع السكربتات
temp_dir = "sovereign_temp_build"
if os.path.exists(temp_dir):
    shutil.rmtree(temp_dir)
os.makedirs(temp_dir)

# 2️⃣ قائمة كل سكربتات النظام الأساسية
scripts = [
    "sovereign_hyper_system.py",
    "sovereign_legendary_autonomous.py",
    "sovereign_legendary_dashboard.py",
    "sovereign_ultimate_ai.py",
    # أضف أي سكربتات أساسية أخرى هنا
]

# 3️⃣ نسخ السكربتات إلى المجلد المؤقت
for s in scripts:
    if os.path.exists(s):
        shutil.copy(s, temp_dir)
        print(f"📂 Copied: {s}")

os.chdir(temp_dir)

# 4️⃣ منح صلاحيات تنفيذ لكل سكربت
os.system("chmod +x *.py")

# 5️⃣ تثبيت PyInstaller لو غير مثبت
try:
    import PyInstaller
except ImportError:
    print("📦 Installing PyInstaller...")
    os.system("pip install --user pyinstaller")

# 6️⃣ دمج كل السكربتات في سكربت واحد رئيسي (launcher)
main_launcher = "sovereign_launcher.py"
with open(main_launcher, "w") as f:
    f.write("import subprocess\n")
    for s in scripts:
        f.write(f"subprocess.Popen(['python3', '{os.path.basename(s)}'])\n")
    f.write("input('🚀 Press Enter to exit after all processes finish...')\n")

# 7️⃣ بناء ملف واحد تنفيذي مستقل
exe_name = "sovereign_ultimate_single"
print(f"🚀 Building Ultimate Single Binary: {exe_name} ...")
os.system(f"pyinstaller --onefile --noconsole {main_launcher}")

print("🎉 Ultimate Single Binary created!")
print("👉 Find it in 'dist/sovereign_ultimate_single'")
print("👉 Run it directly: ./dist/sovereign_ultimate_single")
