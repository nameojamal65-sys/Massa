#!/bin/bash
# =======================================
# PAI6 Auto Scan & Report Viewer
# Fully Automatic
# =======================================

ROOT="$HOME/PAI6_UltimateClosure"
REPORT_DIR="$ROOT/reports"

# إنشاء مجلد التقارير إذا لم يكن موجود
mkdir -p "$REPORT_DIR"

# مصفوفة السكربتات الممكنة
SCRIPTS=("scan_real.py" "scan_independent.py")

for SCAN_SCRIPT in "${SCRIPTS[@]}"; do
    FULL_PATH="$HOME/$SCAN_SCRIPT"
    if [ -f "$FULL_PATH" ]; then
        echo "🔹 بدء التحليل بواسطة $SCAN_SCRIPT ..."
        python3 "$FULL_PATH"

        # البحث عن أحدث تقرير TXT
        REPORT_FILE=$(ls -t "$REPORT_DIR"/*.txt 2>/dev/null | head -n 1)
        if [ -f "$REPORT_FILE" ]; then
            echo "✅ التحليل اكتمل، عرض التقرير:"
            echo "--------------------------------"
            cat "$REPORT_FILE"
            echo "--------------------------------"
        else
            echo "❌ لم يتم العثور على أي تقرير TXT في $REPORT_DIR"
        fi
    else
        echo "❌ السكربت $SCAN_SCRIPT غير موجود في $HOME"
    fi
done
