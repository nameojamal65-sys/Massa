#!/data/data/com.termux/files/usr/bin/python3
# ===============================================
# Shadow Doctor X — Autonomous System Inspector
# Termux Edition (Stable)
# ===============================================

import os
import sys
import time
import json
import hashlib
from collections import defaultdict

def detect_root():
    home = os.path.expanduser("~")
    targets = ["sovereign_core", "pai6", "pai6_memory_ui"]
    for root, dirs, files in os.walk(home):
        for t in targets:
            if t in dirs:
                return os.path.join(root, t)
    return home

ROOT = detect_root()

REPORT = {
    "root": ROOT,
    "files": 0,
    "python_files": 0,
    "lines": 0,
    "size_mb": 0,
    "imports": defaultdict(int),
    "errors": [],
}

def scan():
    for root, dirs, files in os.walk(ROOT):
        for f in files:
            path = os.path.join(root, f)
            try:
                REPORT["files"] += 1
                REPORT["size_mb"] += os.path.getsize(path)

                if f.endswith(".py"):
                    REPORT["python_files"] += 1
                    with open(path, "r", errors="ignore") as fh:
                        for line in fh:
                            REPORT["lines"] += 1
                            line = line.strip()
                            if line.startswith("import ") or line.startswith("from "):
                                mod = line.split()[1].split('.')[0]
                                REPORT["imports"][mod] += 1

            except Exception as e:
                REPORT["errors"].append(str(e))

def analyze():
    warn = []
    if REPORT["python_files"] < 20:
        warn.append("Weak Python footprint")
    if REPORT["lines"] < 5000:
        warn.append("Low code density")
    return warn

def main():
    print("\n🦂 Shadow Doctor X scanning...\n")
    scan()
    warnings = analyze()

    print("📁 Root:", ROOT)
    print("📦 Files:", REPORT["files"])
    print("🐍 Python:", REPORT["python_files"])
    print("📏 Lines:", REPORT["lines"])
    print("💾 Size:", round(REPORT["size_mb"]/1024/1024, 2), "MB")

    if warnings:
        print("\n⚠️ Warnings:")
        for w in warnings:
            print(" -", w)
    else:
        print("\n✅ No structural warnings detected")

    with open("shadow_report.json", "w") as f:
        json.dump(REPORT, f, indent=2)

    print("\n📄 Report saved: shadow_report.json")
    print("\n☠️ Mission completed\n")

if __name__ == "__main__":
    main()
