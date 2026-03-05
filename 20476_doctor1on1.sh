#!/data/data/com.termux/files/usr/bin/bash
# =========================================
# Doctor 1-on-1: تشغيل وفحص منظومة السكربتات
# =========================================

ROOT="$HOME/PAI6_System"      # ضع هنا مسار مجلد المشروع الرئيسي
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/run.log"

mkdir -p "$CORE_DIR" "$MODULES_DIR" "$LOG_DIR"

echo "🚀 Doctor 1-on-1 بدء التشغيل..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
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
            log "$NAME تم تشغيله بنجاح ✅"
        else
            log "$NAME فشل في التشغيل ❌"
        fi
    done
}

# --- التنفيذ ---
log "بدء فحص وتشغيل المنظومة..."

run_scripts_in_dir "$CORE_DIR"
run_scripts_in_dir "$MODULES_DIR"

log "✅ انتهاء Doctor 1-on-1: كل السكربتات تمت مراجعتها وتشغيلها."
echo "==================================="
echo "📁 سجل التشغيل موجود في $LOG_FILE"
