#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor 1-on-1 Ultra: تشغيل وفحص وتحليل السكربتات تلقائياً
# =====================================================

ROOT="$HOME/PAI6_System"      # ضع هنا مسار مجلد المشروع الرئيسي
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/run.log"

mkdir -p "$CORE_DIR" "$MODULES_DIR" "$LOG_DIR"

echo "🚀 Doctor 1-on-1 Ultra بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

analyze_error() {
    local SCRIPT="$1"
    # محاولة بسيطة لتحديد سبب الفشل
    if [ ! -f "$SCRIPT" ]; then
        echo "❌ الملف مفقود"
    elif [ ! -x "$SCRIPT" ] && [[ "$SCRIPT" == *.sh ]]; then
        echo "❌ لا يمتلك صلاحية التنفيذ (chmod +x)"
    elif [[ "$SCRIPT" == *.py ]]; then
        python3 -m py_compile "$SCRIPT" &>/dev/null
        if [ $? -ne 0 ]; then
            echo "❌ خطأ برمجي في السكربت"
        else
            echo "❌ سبب غير محدد"
        fi
    else
        echo "❌ سبب غير محدد"
    fi
}

run_scripts_in_dir() {
    DIR="$1"
    echo "📂 تشغيل سكربتات في $DIR"
    for FILE in "$DIR"/*; do
        [ -f "$FILE" ] || continue
        NAME=$(basename "$FILE")
        log "تشغيل $NAME ..."
        if [[ "$FILE" == *.py ]]; then
            python3 "$FILE"
        elif [[ "$FILE" == *.sh ]]; then
            bash "$FILE"
        else
            log "تجاهل $NAME (ليس سكربت مدعوم)"
            continue
        fi
        if [ $? -eq 0 ]; then
            log "$NAME ✅ تم تشغيله بنجاح"
        else
            ERROR_MSG=$(analyze_error "$FILE")
            log "$NAME ❌ فشل في التشغيل → $ERROR_MSG (تم التجاهل واستمرار التشغيل)"
        fi
    done
}

# --- تنفيذ ---
log "بدء فحص وتشغيل وتحليل المنظومة تلقائياً..."

run_scripts_in_dir "$CORE_DIR"
run_scripts_in_dir "$MODULES_DIR"

log "✅ انتهاء Doctor 1-on-1 Ultra: كل السكربتات تمت مراجعتها وتشغيلها."
echo "==================================="
echo "📁 سجل التشغيل موجود في $LOG_FILE"
echo "💡 أي سكربت معطل سيتم تسجيل السبب لتسهيل الإصلاح"
