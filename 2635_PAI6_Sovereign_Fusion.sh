#!/usr/bin/env bash
# 🚀 PAI6 Sovereign Fusion Script
# =================================
# سكربت نووي واحد لإعادة تنظيم وتشغيل المنظومة السيادية بالكامل
# يشمل: الفحص العميق، الشجرة النهائية، الهيكل المعماري، التقارير، التشغيل الكامل

ROOT="$HOME/PAI6_UltimateClosure"
REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"

PYTHON_SCRIPT="$ROOT/deep_diver_master_temp.py"

# -----------------------------
# 1️⃣ إنشاء سكربت Python داخلي للفحص والتنظيم
# -----------------------------
cat << 'EOF' > "$PYTHON_SCRIPT"
#!/usr/bin/env python3
import os, json, re, hashlib, time
from pathlib import Path

ROOT = Path.home() / "PAI6_UltimateClosure"
REPORT_DIR = ROOT / "reports"
REPORT_TXT = REPORT_DIR / "PAI6_sovereign_fusion_report.txt"
REPORT_JSON = REPORT_DIR / "PAI6_sovereign_fusion_report.json"

DATA = {
"files": 0,
"folders": 0,
"lines": 0,
"size_bytes": 0,
"entry_points": [],
"imports": {},
"functions": 0,
"classes": 0,
"hashes": {},
"warnings": []
}

def analyze_file(path):
try:
content = path.read_text(errors="ignore")
DATA["lines"] += content.count("\n")
DATA["size_bytes"] += path.stat().st_size
DATA["hashes"][str(path)] = hashlib.md5(content.encode(errors="ignore")).hexdigest()

for line in content.splitlines():
if re.match(r"\s*def\s+", line):
DATA["functions"] += 1
DATA["entry_points"].append(f"{path}:{line.strip()}")
if re.match(r"\s*class\s+", line):
DATA["classes"] += 1
DATA["entry_points"].append(f"{path}:{line.strip()}")
if re.match(r"\s*import\s+|\s*from\s+", line):
DATA["imports"].setdefault(str(path), []).append(line.strip())

except Exception as e:
DATA["warnings"].append(f"{path} -> {str(e)}")

def scan():
for root, dirs, files in os.walk(ROOT):
DATA["folders"] += len(dirs)
for f in files:
DATA["files"] += 1
analyze_file(Path(root) / f)

# -----------------------------
# 2️⃣ تنفيذ الفحص
# -----------------------------
scan()

# -----------------------------
# 3️⃣ حساب Cohesion Index
# -----------------------------
cohesion = min(100, round(
(DATA["files"]*0.15 +
DATA["functions"]*0.25 +
DATA["classes"]*0.2 +
len(DATA["entry_points"])*0.2 +
DATA["folders"]*0.2)/10,2))
DATA["cohesion_index"] = cohesion

# -----------------------------
# 4️⃣ توليد التقارير النهائية
# -----------------------------
with open(REPORT_TXT, "w", encoding="utf-8") as f:
f.write("🚀 PAI6 SOVEREIGN FUSION REPORT\n\n")
f.write(f"Root: {ROOT}\n\n")
f.write(f"📂 Folders: {DATA['folders']}\n")
f.write(f"📄 Files: {DATA['files']}\n")
f.write(f"📏 Lines: {DATA['lines']}\n")
f.write(f"⚙ Functions: {DATA['functions']}\n")
f.write(f"🏛 Classes: {DATA['classes']}\n")
f.write(f"🧬 Entry Points: {len(DATA['entry_points'])}\n")
f.write(f"💾 Total Size: {round(DATA['size_bytes']/1024/1024,2)} MB\n")
f.write(f"\n⚡ Cohesion Index: {cohesion}/100\n")
if DATA["warnings"]:
f.write("\n⚠ WARNINGS:\n")
for w in DATA["warnings"]:
f.write(f" - {w}\n")

with open(REPORT_JSON, "w", encoding="utf-8") as f:
json.dump(DATA, f, indent=4, ensure_ascii=False)

# -----------------------------
# 5️⃣ تنظيم الهيكل الداخلي / الشجرة النهائية
# -----------------------------
FINAL_STRUCTURE = {
"SovereignCore": ["core", "dashboard", "scanner"],
"UI": ["kivy_app", "windows_build"],
"Logs": ["logs", "global_run.log"],
"Temp": ["tmp", "cache"]
}

for k, v in FINAL_STRUCTURE.items():
folder_path = ROOT / k
folder_path.mkdir(exist_ok=True)
for sub in v:
(folder_path / sub).mkdir(exist_ok=True)

print("\n✅ Deep Fusion Scan & Organization Completed Successfully")
print(f"📄 TXT Report: {REPORT_TXT}")
print(f"📊 JSON Report: {REPORT_JSON}")
print(f"⚡ Cohesion Index: {cohesion}/100")
EOF

# -----------------------------
# 2️⃣ إعطاء صلاحيات وتنفيذ السكربت
# -----------------------------
chmod +x "$PYTHON_SCRIPT"
python3 "$PYTHON_SCRIPT"

# -----------------------------
# 3️⃣ تنظيف مؤقتات
# -----------------------------
rm -f "$PYTHON_SCRIPT"

echo "🚀 PAI6 Sovereign Fusion Script Finished"