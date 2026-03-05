#!/data/data/com.termux/files/usr/bin/python3
# ===============================
# Shadow Doctor X v3 — Nuclear Core
# Codename: Good Evil Brother v3 😈
# Mission: Deep system inspection, smart report & self-terminate
# ===============================

import os, sys, time, json, hashlib
from collections import defaultdict

# -------- Config --------
ROOT = os.path.expanduser("~/sovereign_core")  # عدّل المسار إذا لزم
REPORT_FILE = os.path.join(ROOT, "shadow_report_v3.json")

# -------- Internal Report Structure --------
R = {
    "root": ROOT,
    "files": 0,
    "python_files": 0,
    "lines": 0,
    "size_mb": 0,
    "modules": set(),
    "imports": defaultdict(int),
    "errors": [],
    "warnings": [],
    "hashes": {},
    "graph": defaultdict(set)
}

# -------- Core Scanner --------
def scan():
    for root, dirs, files in os.walk(ROOT):
        for f in files:
            path = os.path.join(root, f)
            try:
                R["files"] += 1
                size = os.path.getsize(path)
                R["size_mb"] += size
                if f.endswith(".py"):
                    R["python_files"] += 1
                    with open(path, "r", errors="ignore") as fh:
                        lines = fh.readlines()
                        R["lines"] += len(lines)
                        for l in lines:
                            l = l.strip()
                            if l.startswith("import ") or l.startswith("from "):
                                R["modules"].add(l)
                                mod = l.split()[1].split('.')[0]
                                R["imports"][mod] += 1
                                R["graph"][path].add(mod)
                # Binary hash
                with open(path, 'rb') as fh:
                    data = fh.read()
                    R["hashes"][path] = hashlib.md5(data).hexdigest()
            except Exception as e:
                R["errors"].append(f"{path} -> {e}")

# -------- System Intelligence Analysis --------
def analyze():
    if R["files"] < 100:
        R["warnings"].append("Very small system footprint")
    if R["lines"] < 8000:
        R["warnings"].append("Low code density")
    if len(R["modules"]) < 20:
        R["warnings"].append("Weak modular diversity")
    if len(R["errors"]) > 0:
        R["warnings"].append("Runtime instability risk")

# -------- Report Generator --------
def build_report():
    print("\n🦂 SHADOW DOCTOR X — SOVEREIGN DIAGNOSTIC REPORT\n")
    print("="*70)
    print(f"📁 Root: {R['root']}")
    print(f"📦 Files: {R['files']}")
    print(f"🐍 Python Files: {R['python_files']}")
    print(f"📏 Lines of Code: {R['lines']}")
    print(f"💾 System Weight: {round(R['size_mb']/1024/1024,2)} MB")
    print(f"🧠 Unique Modules: {len(R['modules'])}")
    print("="*70)

    print("\n⚠️ Warnings:")
    if R["warnings"]:
        for w in R["warnings"]:
            print(" -", w)
    else:
        print(" None")

    print("\n❌ Errors:")
    if R["errors"]:
        for e in R["errors"]:
            print(" -", e)
    else:
        print(" None")

    integrity = "HIGH"
    if R["warnings"] or R["errors"]:
        integrity = "MEDIUM"
    if len(R["errors"]) > 5:
        integrity = "LOW"

    print("\n🧬 Sovereign Integrity Level:", integrity)
    print("\n🧨 SHADOW VERDICT:")
    if integrity == "HIGH":
        print(" System is Sovereign-Class Ready.")
    elif integrity == "MEDIUM":
        print(" System stable but requires reinforcement.")
    else:
        print(" Critical vulnerabilities detected.")

    print("\n☠️ Mission completed — exiting.")

    # Save JSON report
    try:
        with open(REPORT_FILE, "w") as fh:
            json.dump(R, fh, indent=2)
        print(f"\n📄 Report saved: {REPORT_FILE}")
    except Exception as e:
        print(f"❌ Failed to save report: {e}")

# -------- Execution --------
if __name__ == "__main__":
    print("🕷️ Shadow Doctor X infiltrating...\n")
    time.sleep(1)
    scan()
    analyze()
    build_report()
    time.sleep(2)
    sys.exit(0)
