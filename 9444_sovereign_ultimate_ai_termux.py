#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sovereign Ultimate AI Executor (Termux Version)
Author: ناصر جوابره
"""

import os
import json
from pathlib import Path
from collections import defaultdict

# ========================
# Configuration
# ========================
PROJECT_ROOT = Path(os.getcwd())
REPORT_FILE = PROJECT_ROOT / "sovereign_ai_report.json"
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "ضع_مفتاحك_هنا")

# ========================
# Attempt to import openai
# ========================
try:
    import openai
except ImportError:
    print("⚠️ OpenAI package not found. تثبيت يدوي مطلوب:")
    print("pkg install python-pip")
    print("pip install --user --upgrade openai")
    openai = None

# ========================
# Helper Functions
# ========================
def scan_files(root_path):
    files_info = []
    for path in root_path.rglob("*"):
        if path.is_file():
            files_info.append({
                "name": str(path.relative_to(root_path)),
                "size": path.stat().st_size,
                "ext": path.suffix.lower()
            })
    return files_info

def classify_file(file):
    ext_map = {
        ".py": "AI" if "analyze" in file["name"] else "Data",
        ".jsx": "Dashboard",
        ".html": "Dashboard",
        ".json": "Data",
        ".md": "Other",
        ".txt": "Other"
    }
    return ext_map.get(file["ext"], "Other")

def generate_report(files):
    report = defaultdict(list)
    for f in files:
        category = classify_file(f)
        report[category].append(f)
    report["summary"] = {
        "total_files": len(files),
        "categories": {k: len(v) for k,v in report.items() if k != "summary"}
    }
    return report

def save_report(report):
    with open(REPORT_FILE, "w") as f:
        json.dump(report, f, indent=4)
    print(f"✅ Report saved: {REPORT_FILE}")

def ai_suggestions(report):
    if openai is None:
        print("❌ لا يمكن الحصول على اقتراحات AI بدون تثبيت openai package")
        return None

    prompt = f"""
    قم بتحليل مشروع برمجي يحتوي على الملفات التالية:
    {json.dumps(report, indent=2)}
    اقترح تحسينات هندسية وتنفيذ AI Executor.
    """
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        suggestion = response.choices[0].message.content
        print("🤖 AI Suggestion:\n", suggestion)
        return suggestion
    except Exception as e:
        print("❌ AI suggestion failed:", e)
        return None

# ========================
# Main Execution
# ========================
def main():
    print("🚀 Sovereign Ultimate AI Starting (Termux)...")
    files = scan_files(PROJECT_ROOT)
    print(f"📂 Found {len(files)} files")

    report = generate_report(files)
    save_report(report)
    
    suggestion = ai_suggestions(report)
    
    print("💡 Execution Complete. System Ready.")

if __name__ == "__main__":
    main()
