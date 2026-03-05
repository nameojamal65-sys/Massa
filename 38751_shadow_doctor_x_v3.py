#!/data/data/com.termux/files/usr/bin/python3
# ============================================================
# Shadow Doctor X v3 — Built‑in Sovereign System Inspector
# Codename: Good Evil Brother 😈
# Mission: Deep system inspection, smart diagnosis, clean exit
# ============================================================

import os, sys, time, json, hashlib
from collections import defaultdict

# ---------- Smart Root Detection ----------
def detect_root():
    home = os.path.expanduser("~")
    candidates = ["sovereign_core", "pai6", "pai6_core", "pai6_memory_ui"]
    for root, dirs, files in os.walk(home):
        for c in candidates:
            if c in dirs:
                return os.path.join(root, c)
    return home

ROOT = detect_root()
REPORT_FILE = os.path.join(ROOT, "shadow_report_v3.json")

# ---------- Internal Report Structure ----------
R = {
    "root": ROOT,
    "files": 0,
    "python_files": 0,
    "lines": 0,
    "size_bytes": 0,
    "modules": set(),
    "imports": defaultdict(int),
    "errors": [],
    "warnings": [],
}

# ---------- Core Scanner ----------
def scan():
    for root, dirs, files in os.walk(ROOT):
        for f in files:
            path = os.path.join(root, f)
            try:
                R["files"] += 1
                size = os.path.getsize(path)
                R["size_bytes"] += size

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

                with open(path, 'rb') as fh:
                    hashlib.md5(fh.read()).hexdigest()

            except Exception as e:
                if "node_modules" not in path:
                    R["errors"].append(f"{path} -> {e}")

# ---------- Logical Analysis ----------
def analyze():
    if R["files"] < 200:
        R["warnings"].append("System footprint too small")
    if R["lines"] < 12000:
        R["warnings"].append("Low code density")
    if len(R["modules"]) < 25:
        R["warnings"].append("Weak modular diversity")
    if len(R["errors"]) > 0:
        R["warnings"].append("Runtime instability risk")

# ---------- Report Builder ----------
def build_report():
    size_mb = round(R["size_bytes"] / 1024 / 1024, 2)

    print("\n🦂 SHADOW DOCTOR X v3 — BUILT‑IN DIAGNOSTIC REPORT\n")
    print("=" * 70)
    print(f"📁 Root: {R['root']}")
    print(f"📦 Files: {R['files']}")
    print(f"🐍 Python Files: {R['python_files']}")
    print(f"📏 Lines of Code: {R['lines']}")
    print(f"💾 System Weight: {size_mb} MB")
    print(f"🧠 Unique Modules: {len(R['modules'])}")
    print("=" * 70)

    print("\n⚠️ Warnings:")
    if R["warnings"]:
        for w in R["warnings"]:
            print(" -", w)
    else:
        print(" None")

    print("\n❌ Errors:")
    if R["errors"]:
        for e in R["errors"][:10]:
            print(" -", e)
        if len(R["errors"]) > 10:
            print(f" ... +{len(R['errors']) - 10} more")
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
        print(" System is Sovereign‑Class Ready.")
    elif integrity == "MEDIUM":
        print(" System stable but requires reinforcement.")
    else:
        print(" Critical vulnerabilities detected.")

    export = dict(R)
    export["modules"] = list(R["modules"])
    export["imports"] = dict(R["imports"])

    with open(REPORT_FILE, "w") as fh:
        json.dump(export, fh, indent=2)

    print(f"\n📄 Report saved to: {REPORT_FILE}")
    print("\n☠️ Mission completed — self destruct in 3s...\n")
    time.sleep(3)

# ---------- Execution ----------
if __name__ == "__main__":
    print("🕷️ Shadow Doctor X v3 infiltrating...\n")
    time.sleep(1)
    scan()
    analyze()
    build_report()
    sys.exit(0)
