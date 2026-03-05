#!/usr/bin/env python3
import os
from pathlib import Path

# -----------------------------
# إعداد المسارات
# -----------------------------
ROOT = Path.home() / "PAI6_UltimateClosure"
REPORT_TXT = ROOT / "reports/PAI6_architecture_report.txt"

# المجلدات الأساسية المتوقعة
expected_folders = ["core", "dashboard", "scanner", "kivy_app", "windows_build"]
# الملفات الأساسية المتوقعة لكل مجلد (يمكن تعديل حسب البنية)
expected_files = {
    "core": ["__init__.py", "core.py"],
    "dashboard": ["__init__.py", "main.py"],
    "scanner": ["__init__.py"],
    "kivy_app": ["main.kv"],
    "windows_build": ["build_config.json"]
}

# -----------------------------
# وظائف مساعدة
# -----------------------------
def check_folder(folder):
    path = ROOT / folder
    return path.exists(), len(list(path.glob('**/*')) if path.exists() else [])

def check_files(folder):
    path = ROOT / folder
    files_expected = expected_files.get(folder, [])
    found = 0
    for f in files_expected:
        if (path / f).exists():
            found += 1
    return found, len(files_expected)

def count_lines(path, ext):
    total = 0
    for f in path.rglob(f"*.{ext}"):
        try:
            with open(f, "r", encoding="utf-8") as file:
                total += len(file.readlines())
        except:
            continue
    return total

# -----------------------------
# جمع البيانات
# -----------------------------
report = {}
report["folders"] = {}
report["files"] = {}
report["lines"] = {}

for folder in expected_folders:
    exists, n_files = check_folder(folder)
    report["folders"][folder] = {"exists": exists, "file_count": n_files}
    
    found, expected = check_files(folder)
    report["files"][folder] = {"found": found, "expected": expected}

# عدد أسطر الكود
report["lines"]["python"] = count_lines(ROOT, "py")
report["lines"]["js"] = count_lines(ROOT, "js")
report["lines"]["sh"] = count_lines(ROOT, "sh")

# -----------------------------
# حساب مؤشر التماسك
# -----------------------------
folder_score = sum(1 for f in report["folders"].values() if f["exists"]) / len(expected_folders)
files_score = sum(f["found"]/f["expected"] for f in report["files"].values()) / len(expected_folders)
line_score = 1.0 if max(report["lines"].values()) < 5000 else 0.8  # مثال: ملفات ضخمة تقلل التماسك

report["cohesion_index"] = round((folder_score*0.4 + files_score*0.4 + line_score*0.2)*100, 2)

# -----------------------------
# طباعة التقرير
# -----------------------------
os.makedirs(ROOT / "reports", exist_ok=True)
with open(REPORT_TXT, "w") as f:
    f.write("📊 PAI6 Architecture & Cohesion Report\n\n")
    f.write(f"ROOT: {ROOT}\n\n")
    f.write("🗂 Folders:\n")
    for k,v in report["folders"].items():
        f.write(f" - {k}: {'✅' if v['exists'] else '⚠️'} ({v['file_count']} files)\n")
    f.write("\n📄 Files Check:\n")
    for k,v in report["files"].items():
        f.write(f" - {k}: {v['found']}/{v['expected']} files found\n")
    f.write("\n📏 Lines of Code:\n")
    for k,v in report["lines"].items():
        f.write(f" - {k}: {v} lines\n")
    f.write(f"\n⚡ Cohesion Index: {report['cohesion_index']} / 100\n")

print(f"✅ Architecture report generated: {REPORT_TXT}")
print(f"⚡ Cohesion Index: {report['cohesion_index']} / 100")
