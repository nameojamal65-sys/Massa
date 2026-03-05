#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor 1-on-1 Master Ultra: إعادة كتابة المنظومة بالكامل
# =====================================================

ROOT="$HOME/PAI6_System"
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
CLEAN_DIR="$ROOT/PAI6_Cleaned"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/run.log"
TARGET_DIR="/storage/emulated/0/ملفاتي/PAI6_Cleaned"

mkdir -p "$CLEAN_DIR/core" "$CLEAN_DIR/modules" "$LOG_DIR" "$TARGET_DIR"

echo "🚀 Doctor 1-on-1 Master Ultra بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

clean_and_copy() {
    SRC="$1"
    DST="$2"
    for FILE in "$SRC"/*; do
        [ -f "$FILE" ] || continue
        NAME=$(basename "$FILE")
        EXT="${NAME##*.}"
        log "معالجة $NAME ..."

        # إصلاح الصلاحيات للـ .sh
        if [[ "$EXT" == "sh" ]]; then
            chmod +x "$FILE"
        fi

        # تحقق من .py
        if [[ "$EXT" == "py" ]]; then
            python3 -m py_compile "$FILE" &>/dev/null
            if [ $? -ne 0 ]; then
                log "$NAME ❌ يحتوي على خطأ برمجي محتمل"
            fi
        fi

        # تنظيف السكربت: حذف التعليقات الفارغة وتقليل الفراغات الزائدة
        CLEAN_FILE=$(mktemp)
        grep -vE '^\s*#' "$FILE" | sed '/^\s*$/d' > "$CLEAN_FILE"

        cp "$CLEAN_FILE" "$DST/$NAME"
        rm "$CLEAN_FILE"
        log "$NAME ✅ تم تنظيفه ونسخه"
    done
}

# --- تنفيذ ---
log "بدء إعادة كتابة كل السكربتات..."

clean_and_copy "$CORE_DIR" "$CLEAN_DIR/core"
clean_and_copy "$MODULES_DIR" "$CLEAN_DIR/modules"

# نسخ النسخة النهائية إلى ملفاتي
cp -r "$CLEAN_DIR/." "$TARGET_DIR/"
log "✅ جميع السكربتات تم إعادة كتابتها وتنظيفها ونقلها إلى $TARGET_DIR"

echo "==================================="
echo "📁 العملية اكتملت. سجل التشغيل: $LOG_FILE"
echo "💡 النسخة النهائية موجودة في: $TARGET_DIR"
