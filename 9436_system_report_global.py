#!/usr/bin/env python3
import os
from datetime import datetime

# Paths
BASE_DIR = os.path.expanduser("~/sovereign_system_fixed/sovereign_system")
REPORTS_DIR = os.path.join(BASE_DIR, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)

# Helper to format size
def sizeof_fmt(num, suffix="B"):
    for unit in ["","K","M","G","T","P"]:
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f}P{suffix}"

# Initialize counters
total_files = 0
total_lines = 0
total_size = 0
file_details = []

# Scan all files
for root, dirs, files in os.walk(BASE_DIR):
    for f in files:
        total_files += 1
        path = os.path.join(root, f)
        size = os.path.getsize(path)
        total_size += size

        # Count lines for text files
        lines = 0
        if f.endswith((".py",".sh",".txt")):
            try:
                with open(path, "r", encoding="utf-8") as file:
                    lines = sum(1 for _ in file)
            except:
                lines = 0
        total_lines += lines
        file_details.append((path.replace(BASE_DIR+"/",""), sizeof_fmt(size), lines))

# Prepare report text
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
report_file = os.path.join(REPORTS_DIR, f"system_report_{timestamp}.txt")

report_text = [
    f"🚀 System Report for Sovereign System 🚀",
    f"Base Directory: {BASE_DIR}",
    f"Total Files: {total_files}",
    f"Total Size: {sizeof_fmt(total_size)}",
    f"Total Lines (text files): {total_lines}\n",
    "📄 File Details:"
]

for f, size, lines in file_details:
    report_text.append(f"{f:30} | Size: {size:8} | Lines: {lines}")

report_text.append("\n✅ Report generated successfully!")

# Write report
with open(report_file, "w", encoding="utf-8") as f:
    f.write("\n".join(report_text))

# Print location
print("\n".join(report_text))
print(f"\n📝 Report saved to: {report_file}")
