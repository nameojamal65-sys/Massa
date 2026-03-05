#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor Code Summary Report: تقرير شامل للكود الحقيقي
# =====================================================

EXTRACT_DIR="$HOME/PAI6_System/PAI6_Code_Only"
LOG_DIR="$HOME/PAI6_System/logs"
LOG_FILE="$LOG_DIR/code_report_summary.log"

mkdir -p "$LOG_DIR"

echo "🚀 Doctor Code Summary Report بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

analyze_dir() {
    DIR="$1"
    echo "📂 تحليل مجلد: $DIR"
    log "تحليل مجلد: $DIR"

    TOTAL_LINES=0
    TOTAL_SIZE=0
    COUNT=0

    for FILE in "$DIR"/*; do
        [ -f "$FILE" ] || continue
        COUNT=$((COUNT+1))
        NAME=$(basename "$FILE")
        LINES=$(wc -l < "$FILE")
        SIZE_BYTES=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE") # دعم Termux
        TOTAL_LINES=$((TOTAL_LINES + LINES))
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))
        SIZE_HUMAN=$(du -h "$FILE" | cut -f1)
        echo "- $NAME | Lines: $LINES | Size: $SIZE_HUMAN"
        log "- $NAME | Lines: $LINES | Size: $SIZE_HUMAN"
    done

    TOTAL_SIZE_HUMAN=$(du -sh "$DIR" 2>/dev/null | cut -f1)
    echo "عدد السكربتات في $DIR: $COUNT"
    echo "مجموع الأسطر: $TOTAL_LINES"
    echo "الوزن الكلي: $TOTAL_SIZE_HUMAN"
    echo "-----------------------------------"

    log "عدد السكربتات في $DIR: $COUNT"
    log "مجموع الأسطر: $TOTAL_LINES"
    log "الوزن الكلي: $TOTAL_SIZE_HUMAN"
}

# --- تنفيذ ---
log "بدء إنشاء التقرير النهائي لكل الكود المعزول..."

analyze_dir "$EXTRACT_DIR/core"
analyze_dir "$EXTRACT_DIR/modules"

echo "✅ التقرير النهائي اكتمل. سجل التقرير: $LOG_FILE"
echo "==================================="
