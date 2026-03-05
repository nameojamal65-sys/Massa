#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import platform
import subprocess
import time
from datetime import datetime

BASE_DIR = os.path.expanduser("~/PAI6")
os.makedirs(BASE_DIR, exist_ok=True)

JSON_REPORT = os.path.join(BASE_DIR, "PAI6_SYSTEM_REPORT.json")
TXT_REPORT  = os.path.join(BASE_DIR, "PAI6_SYSTEM_REPORT.txt")

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
    except:
        return "N/A"

def analyze_system():
    report = {}
    report["timestamp"] = datetime.utcnow().isoformat()
    report["platform"] = platform.platform()
    report["architecture"] = platform.machine()
    report["python_version"] = platform.python_version()
    report["cpu_info"] = run("lscpu | head -n 20")
    report["memory"] = run("free -h")
    report["disk"] = run("df -h /")
    report["processes"] = run("ps aux | wc -l")
    report["network"] = run("ip a | head -n 50")

    core_checks = {
        "configs": os.path.exists("configs"),
        "core": os.path.exists("core"),
        "scripts": os.path.exists("scripts"),
        "logs": os.path.exists("logs"),
        "dashboard": os.path.exists("package.json"),
        "launcher": os.path.exists("core_launcher.py")
    }

    report["core_integrity"] = core_checks

    score = 0

    score += 20 if core_checks["core"] else 0
    score += 10 if core_checks["configs"] else 0
    score += 10 if core_checks["scripts"] else 0
    score += 10 if core_checks["logs"] else 0
    score += 20 if core_checks["dashboard"] else 0
    score += 10 if core_checks["launcher"] else 0
    score += 20 if int(run("ps aux | wc -l") or 0) > 50 else 0

    if score >= 90:
        level = "SOVEREIGN GRADE SYSTEM"
    elif score >= 75:
        level = "ENTERPRISE READY"
    elif score >= 60:
        level = "ADVANCED PROTOTYPE"
    elif score >= 40:
        level = "EXPERIMENTAL SYSTEM"
    else:
        level = "BASIC FRAMEWORK"

    report["score"] = score
    report["level"] = level

    return report

def write_reports(report):
    with open(JSON_REPORT, "w") as f:
        json.dump(report, f, indent=2)

    with open(TXT_REPORT, "w") as f:
        f.write("PAI6 SOVEREIGN SYSTEM DEEP REPORT\n")
        f.write("="*60 + "\n\n")
        for k, v in report.items():
            f.write(f"{k.upper()}:\n{v}\n\n")

def banner():
    print("\nPAI6 - Sovereign Deep Introspector")
    print("="*45)
    print("Scanning autonomous system core...\n")

def main():
    banner()
    time.sleep(1)

    report = analyze_system()
    write_reports(report)

    print("Analysis complete.\n")
    print("Score :", report["score"], "/ 100")
    print("Level :", report["level"])
    print("\nReports generated at:")
    print(JSON_REPORT)
    print(TXT_REPORT)

if __name__ == "__main__":
    main()
