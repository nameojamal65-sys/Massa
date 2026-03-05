#!/usr/bin/env python3
import os
from pathlib import Path

# -----------------------------
# 1️⃣ إعداد ROOT ومسار الملفات
# -----------------------------
ROOT = Path.home() / "PAI6_UltimateClosure"
REPORT_DIR = ROOT / "reports"
REPORT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = REPORT_DIR / "PAI6_full_code.txt"

# -----------------------------
# 2️⃣ جمع كل الملفات
# -----------------------------
with open(OUTPUT_FILE, "w", encoding="utf-8") as out_file:
    for root, dirs, files in os.walk(ROOT):
        for f in files:
            file_path = Path(root) / f
            try:
                content = file_path.read_text(errors="ignore")
                out_file.write(f"\n\n# ===== File: {file_path} =====\n\n")
                out_file.write(content)
            except Exception as e:
                out_file.write(f"\n\n# ===== File: {file_path} -> ERROR: {e} =====\n\n")

print(f"✅ All files collected into: {OUTPUT_FILE}")
