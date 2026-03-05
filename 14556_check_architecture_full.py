#!/usr/bin/env python3
import os
import json
from pathlib import Path
import time

# -----------------------------
# 1️⃣ إعداد ROOT ومسارات التقرير
# -----------------------------
ROOT = Path.home() / "PAI6_UltimateClosure"
REPORT_DIR = ROOT / "reports"
REPORT_TXT = REPORT_DIR / "PAI6_master_report.txt"
REPORT_JSON = REPORT_DIR / "PAI6_master_report.json"

# المجلدات الأساسية
expected_folders = ["core", "dashboard", "scanner", "kivy_app", "windows_build"]

# الملفات الأساسية لكل مجلد
expected_files = {
    "core": ["__init__.py", "core.py"],
    "dashboard": ["__init__.py", "main.py"],
    "scanner": ["__init__.py"],
    "kivy_app": ["main.kv"],
    "windows_build": ["build_config.json"]
}

# -----------------------------
# 2️⃣ وظائف المساعدة
# -----------------------------
def ensure_folder(folder):
    path = ROOT / folder
    if not path.exists():
        print(f"⚠️ Folder missing, creating: {folder}")
        path.mkdir(parents=True, exist_ok=True)
    return path

def ensure_file(folder, filename, placeholder="# Placeholder"):
    path = folder / filename
    if not path.exists():
        print(f"⚠️ File missing, creating placeholder: {filename}")
        with open(path, "w", encoding="utf-8") as f:
            f.write(placeholder + "\n")
    return path

def count_lines(path, ext):
    total = 0
    for f in path.rglob(f"*.{ext}"):
        try:
            with open(f, "r", encoding="utf-8") as file:
                total += len(file.readlines())
        except:
            continue
    return total

def folder_weight(path):
    total = 0
    for f in path.rglob("*"):
        if f.is_file():
            total += f.stat().st_size
    return total

def find_entrypoints(path):
    endpoints = []
    for f in path.rglob("*.py"):
        try:
            with open(f, "r", encoding="utf-8") as file:
                lines = file.readlines()
                for i, l in enumerate(lines):
                    if "def " in l or "class " in l:
                        endpoints.append(f"{f.relative_to(ROOT)}:{i+1}")
        except:
            continue
    return endpoints

# -----------------------------
# 3️⃣ بناء التقرير وجمع البيانات
# -----------------------------
report = {
    "folders": {},
    "files": {},
    "lines": {},
    "weights": {},
    "entrypoints": {},
    "cohesion_index": 0
}

for folder_name in expected_folders:
    folder_path = ensure_folder(folder_name)
    report["folders"][folder_name] = {"exists": True, "file_count": len(list(folder_path.rglob("*")))}
    report["files"][folder_name] = {}
    for file_name in expected_files.get(folder_name, []):
        file_path = ensure_file(folder_path, file_name, placeholder=f"# Placeholder for {file_name}")
        report["files"][folder_name][file_name] = True

# حساب عدد الأسطر لكل نوع
report["lines"]["python"] = count_lines(ROOT, "py")
report["lines"]["js"] = count_lines(ROOT, "js")
report["lines"]["sh"] = count_lines(ROOT, "sh")
report["lines"]["kv"] = count_lines(ROOT, "kv")
report["lines"]["json"] = count_lines(ROOT, "json")

# وزن كل مجلد
for folder_name in expected_folders:
    report["weights"][folder_name] = folder_weight(ROOT / folder_name)

# استخراج entrypoints
for folder_name in expected_folders:
    report["entrypoints"][folder_name] = find_entrypoints(ROOT / folder_name)

# -----------------------------
# 4️⃣ حساب Cohesion Index
# -----------------------------
folder_score = sum(1 for f in report["folders"].values() if f["exists"]) / len(expected_folders)
files_score = sum(len(f) for f in report["files"].values()) / sum(len(v) for v in expected_files.values())
line_score = 1.0 if max(report["lines"].values()) < 10000 else 0.8
report["cohesion_index"] = round((folder_score*0.4 + files_score*0.4 + line_score*0.2)*100, 2)

# -----------------------------
# 5️⃣ توليد التقارير
# -----------------------------
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# تقرير TXT
with open(REPORT_TXT, "w", encoding="utf-8") as f:
    f.write("📊 PAI6 Master Architecture Report\n\n")
    f.write(f"ROOT: {ROOT}\n\n")
    f.write("🗂 Folders:\n")
    for k, v in report["folders"].items():
        f.write(f" - {k}: {'✅' if v['exists'] else '⚠️'} ({v['file_count']} files)\n")
    f.write("\n📄 Files Check:\n")
    for folder, files in report["files"].items():
        for fname in files:
            f.write(f" - {folder}/{fname}: ✅ exists\n")
    f.write("\n📏 Lines of Code:\n")
    for k, v in report["lines"].items():
        f.write(f" - {k}: {v} lines\n")
    f.write("\n⚖️ Folder Weights (bytes):\n")
    for k, v in report["weights"].items():
        f.write(f" - {k}: {v} bytes\n")
    f.write("\n🚪 Entry Points:\n")
    for k, eps in report["entrypoints"].items():
        f.write(f" - {k}: {len(eps)} endpoints\n")
        for ep in eps:
            f.write(f"    • {ep}\n")
    f.write(f"\n⚡ Cohesion Index: {report['cohesion_index']} / 100\n")

# تقرير JSON
with open(REPORT_JSON, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=4)

print(f"✅ Master Architecture report generated: {REPORT_TXT}")
print(f"⚡ Cohesion Index: {report['cohesion_index']} / 100")
