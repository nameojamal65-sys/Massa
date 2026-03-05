#!/data/data/com.termux/files/usr/bin/bash

# === إعدادات ===
BASE="$HOME/sovereign_system"
REPORT="$BASE/ai_report.log"

echo "===== تقرير الكود المتبقي للذكاء الاصطناعي =====" > "$REPORT"
echo "المجلد الأساسي: $BASE" >> "$REPORT"
echo "تاريخ التقرير: $(date)" >> "$REPORT"
echo "------------------------------------------" >> "$REPORT"

# جمع كل ملفات Python
PY_FILES=$(find "$BASE" -type f -name "*.py")

# عدد الملفات
NUM_FILES=$(echo "$PY_FILES" | wc -l)
echo "📁 عدد ملفات Python: $NUM_FILES" >> "$REPORT"

# الحجم الإجمالي
TOTAL_SIZE=$(du -ch $PY_FILES | grep total$ | awk '{print $1}')
echo "💾 الحجم الإجمالي للكود: $TOTAL_SIZE" >> "$REPORT"
echo "------------------------------------------" >> "$REPORT"
echo "💾 تفاصيل كل ملف:" >> "$REPORT"

# لكل ملف Python، حساب الأسطر والحجم
for FILE in $PY_FILES; do
    SIZE=$(stat -c%s "$FILE")
    LINES=$(wc -l < "$FILE")
    echo "- $FILE | الحجم: $SIZE bytes | أسطر: $LINES" >> "$REPORT"
done

echo "===========================================" >> "$REPORT"

echo "✅ التقرير مكتمل: $REPORT"
