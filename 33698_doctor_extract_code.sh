#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor Code Extractor: عزل الكود الحقيقي وإحصائياته
# =====================================================

ROOT="$HOME/PAI6_System"
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
EXTRACT_DIR="$ROOT/PAI6_Code_Only"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/code_report.log"
TARGET_DIR="/storage/emulated/0/ملفاتي/PAI6_Code_Only"

mkdir -p "$EXTRACT_DIR/core" "$EXTRACT_DIR/modules" "$LOG_DIR" "$TARGET_DIR"

echo "🚀 Doctor Code Extractor بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

extract_code() {
    SRC="$1"
    DST="$2"
    NAME=$(basename "$SRC")
    EXT="${NAME##*.}"

    log "معالجة $NAME ..."

    # تنظيف الكود: إزالة التعليقات الفارغة وغير المهمة
    CLEAN_FILE=$(mktemp)
    grep -vE '^\s*#' "$SRC" | sed '/^\s*$/d' > "$CLEAN_FILE"

    cp "$CLEAN_FILE" "$DST/$NAME"

    # حساب عدد الأسطر
    LINES=$(wc -l < "$DST/$NAME")
    # حساب حجم الملف
    SIZE=$(du -h "$DST/$NAME" | cut -f1)

    log "$NAME | الأسطر: $LINES | الحجم: $SIZE"
    echo "- $NAME | Lines: $LINES | Size: $SIZE"
    
    rm "$CLEAN_FILE"
}

run_extract_dir() {
    SRC_DIR="$1"
    DST_DIR="$2"
    for FILE in "$SRC_DIR"/*; do
        [ -f "$FILE" ] || continue
        extract_code "$FILE" "$DST_DIR"
    done
}

# --- تنفيذ ---
log "بدء عزل الكود الحقيقي لكل السكربتات..."

run_extract_dir "$CORE_DIR" "$EXTRACT_DIR/core"
run_extract_dir "$MODULES_DIR" "$EXTRACT_DIR/modules"

# نسخ النسخة النهائية إلى ملفاتي
cp -r "$EXTRACT_DIR/." "$TARGET_DIR/"
log "✅ جميع الأكواد المعزولة تم نسخها إلى $TARGET_DIR"

echo "==================================="
echo "📁 العملية اكتملت. سجل التشغيل: $LOG_FILE"
echo "💡 النسخة النهائية للكود الحقيقي موجودة في: $TARGET_DIR"
