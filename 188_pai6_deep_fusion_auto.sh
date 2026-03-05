#!/bin/bash
ROOT="$HOME/PAI6_UltimateClosure"
REPORT_DIR="$ROOT/reports"
mkdir -p "$REPORT_DIR"
REPORT_TXT="$REPORT_DIR/PAI6_deep_fusion_real_report.txt"
REPORT_JSON="$REPORT_DIR/PAI6_deep_fusion_real_report.json"

command -v python3 >/dev/null 2>&1 || { pkg install python -y; }

echo "🚀 Starting PAI6 Deep Fusion Scan (Auto)..."

python3 - << 'EOPY'
import os, json, re, hashlib, time
from pathlib import Path

ROOT = Path.home() / "PAI6_UltimateClosure"
REPORT_DIR = ROOT / "reports"
REPORT_TXT = REPORT_DIR / "PAI6_deep_fusion_real_report.txt"
REPORT_JSON = REPORT_DIR / "PAI6_deep_fusion_real_report.json"

DATA = {"files":0,"folders":0,"lines":0,"size_bytes":0,"entry_points":[],"imports":{},"functions":0,"classes":0,"hashes":{},"warnings":[]}

def analyze_file(path: Path):
    try:
        content = path.read_text(errors="ignore")
        DATA["lines"] += content.count("\n")
        DATA["size_bytes"] += path.stat().st_size
        DATA["hashes"][str(path)] = hashlib.md5(content.encode(errors="ignore")).hexdigest()
        for line in content.splitlines():
            line_stripped = line.strip()
            if re.match(r"^def\s+", line_stripped): DATA["functions"]+=1; DATA["entry_points"].append(f"{path}:{line_stripped}")
            elif re.match(r"^class\s+", line_stripped): DATA["classes"]+=1; DATA["entry_points"].append(f"{path}:{line_stripped}")
            elif re.match(r"^(import\s+|from\s+)", line_stripped): DATA["imports"].setdefault(str(path), []).append(line_stripped)
    except Exception as e: DATA["warnings"].append(f"{path} -> {str(e)}")

def scan(): 
    for root, dirs, files in os.walk(ROOT):
        DATA["folders"] += len(dirs)
        for f in files: DATA["files"] += 1; analyze_file(Path(root)/f)

def calculate_cohesion():
    cohesion = min(100, round((DATA["files"]*0.2+DATA["functions"]*0.3+DATA["classes"]*0.25+len(DATA["entry_points"])*0.2+DATA["folders"]*0.05),2))
    DATA["cohesion_index"]=cohesion
    return cohesion

def generate_reports():
    cohesion=calculate_cohesion()
    with open(REPORT_TXT,"w",encoding="utf-8") as f:
        f.write("🚀 PAI6 Deep Fusion Real Report\n\n")
        f.write(f"Root: {ROOT}\n\n")
        f.write(f"📂 Folders: {DATA['folders']}\n📄 Files: {DATA['files']}\n📏 Lines: {DATA['lines']}\n⚙ Functions: {DATA['functions']}\n🏛 Classes: {DATA['classes']}\n🧬 Entry Points: {len(DATA['entry_points'])}\n💾 Total Size: {round(DATA['size_bytes']/1024/1024,2)} MB\n\n⚡ Cohesion Index: {cohesion}/100\n")
        if DATA["warnings"]:
            f.write("\n⚠ WARNINGS:\n")
            for w in DATA["warnings"]: f.write(f" - {w}\n")
    with open(REPORT_JSON,"w",encoding="utf-8") as f: json.dump(DATA,f,indent=4,ensure_ascii=False)
    print(f"\n✅ Deep Fusion Real Completed\n📄 TXT: {REPORT_TXT}\n📊 JSON: {REPORT_JSON}\n⚡ Cohesion: {cohesion}/100")

if __name__=="__main__":
    start=time.time()
    scan()
    generate_reports()
    print(f"⏱ Total Scan Time: {round(time.time()-start,2)}s")
EOPY
