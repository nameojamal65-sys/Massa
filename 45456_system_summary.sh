#!/bin/bash
# ⚡ Summary Script for Sovereign System

BASE="$HOME/sovereign_system_fixed/sovereign_system"
REPORT="$BASE/reports/report.txt"

echo "🚀 Sovereign System Summary"
echo "Base Directory: $BASE"
echo

# 1️⃣ عدد الملفات
FILE_COUNT=$(find "$BASE" -type f | wc -l)
echo "📂 Total files: $FILE_COUNT"

# 2️⃣ عدد الأسطر لكل سكربت
echo
echo "📝 Lines per Python script:"
for f in "$BASE"/*.py; do
    LINES=$(wc -l < "$f")
    echo "$(basename "$f"): $LINES lines"
done

# 3️⃣ رؤوس الأقلام من التقرير
echo
echo "📊 Report Highlights:"
grep -E "Total|Processed|Collecting|Report" "$REPORT"

echo
echo "✅ Summary Complete!"
