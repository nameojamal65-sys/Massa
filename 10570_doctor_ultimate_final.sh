#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor 1-on-1 Ultimate Final
# إعادة كتابة، تنظيف، إصلاح، وتشغيل كل السكربتات
# =====================================================

ROOT="$HOME/PAI6_System"
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
FINAL_DIR="$ROOT/PAI6_Final"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/run_final.log"
TARGET_DIR="/storage/emulated/0/ملفاتي/PAI6_Final"

mkdir -p "$FINAL_DIR/core" "$FINAL_DIR/modules" "$LOG_DIR" "$TARGET_DIR"

echo "🚀 Doctor 1-on-1 Ultimate Final بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

process_script_final() {
    SRC="$1"
    DST="$2"
    NAME=$(basename "$SRC")
    EXT="${NAME##*.}"
    FIXED=0

    log "معالجة $NAME ..."

    # إصلاح صلاحية التنفيذ للـ .sh
    if [[ "$EXT" == "sh" ]]; then
        chmod +x "$SRC"
        FIXED=1
    fi

    # التحقق من .py
    if [[ "$EXT" == "py" ]]; then
        python3 -m py_compile "$SRC" &>/dev/null
        if [ $? -ne 0 ]; then
            log "$NAME ⚠️ يحتوي على خطأ برمجي محتمل"
        fi
    fi

    # تنظيف السكربت: حذف التعليقات الفارغة وتقليل الفراغات الزائدة
    CLEAN_FILE=$(mktemp)
    grep -vE '^\s*#' "$SRC" | sed '/^\s*$/d' > "$CLEAN_FILE"
    cp "$CLEAN_FILE" "$DST/$NAME"
    rm "$CLEAN_FILE"

    log "$NAME ✅ تم تنظيفه ونسخه"

    # تجربة تشغيل السكربت بعد التنظيف
    if [[ "$EXT" == "py" ]]; then
        python3 "$DST/$NAME"
    elif [[ "$EXT" == "sh" ]]; then
        bash "$DST/$NAME"
    fi

    if [ $? -eq 0 ]; then
        if [ $FIXED -eq 1 ]; then
            log "$NAME ✅ تم إصلاحه وتشغيله بنجاح بعد التنظيف"
        else
            log "$NAME ✅ تم التشغيل بنجاح بعد التنظيف"
        fi
    else
        log "$NAME ❌ فشل في التشغيل بعد التنظيف (تم التجاهل)"
    fi
}

run_dir_final() {
    SRC_DIR="$1"
    DST_DIR="$2"
    for FILE in "$SRC_DIR"/*; do
        [ -f "$FILE" ] || continue
        process_script_final "$FILE" "$DST_DIR"
    done
}

# --- تنفيذ ---
log "بدء إعادة كتابة، تنظيف، إصلاح، وتشغيل كل السكربتات النهائية..."

run_dir_final "$CORE_DIR" "$FINAL_DIR/core"
run_dir_final "$MODULES_DIR" "$FINAL_DIR/modules"

# نسخ النسخة النهائية إلى ملفاتي
cp -r "$FINAL_DIR/." "$TARGET_DIR/"
log "✅ جميع السكربتات تم تنظيفها، إصلاحها، وتشغيلها، ونقلها إلى $TARGET_DIR"

echo "==================================="
echo "📁 العملية النهائية اكتملت. سجل التشغيل: $LOG_FILE"
echo "💡 النسخة النهائية موجودة في: $TARGET_DIR"
