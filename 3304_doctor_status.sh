#!/data/data/com.termux/files/usr/bin/bash
# =====================================================
# Doctor 0: فحص الوضع الحالي للمنظومة
# =====================================================

ROOT="$HOME/PAI6_System"      
CORE_DIR="$ROOT/core"
MODULES_DIR="$ROOT/modules"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/status.log"

mkdir -p "$CORE_DIR" "$MODULES_DIR" "$LOG_DIR"

echo "🔍 Doctor 0: فحص الوضع الحالي للمنظومة..."
echo "==================================="

log() {
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] $1"
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

check_dir() {
    DIR="$1"
    echo "📂 فحص مجلد: $DIR"
    log "فحص مجلد: $DIR"
    COUNT=0
    for FILE in "$DIR"/*; do
        [ -f "$FILE" ] || continue
        COUNT=$((COUNT+1))
        NAME=$(basename "$FILE")
        SIZE=$(du -h "$FILE" | cut -f1)
        MTIME=$(date -r "$FILE" +"%Y-%m-%d %H:%M:%S")
        if [[ "$FILE" == *.py ]]; then
            python3 -m py_compile "$FILE" &>/dev/null
            if [ $? -eq 0 ]; then
                STATUS="✅ صالح"
            else
                STATUS="❌ معطل/خطأ برمجي"
            fi
        elif [[ "$FILE" == *.sh ]]; then
            if [ -x "$FILE" ]; then
                STATUS="✅ صالح"
            else
                STATUS="❌ بدون صلاحية تنفيذ"
            fi
        else
            STATUS="⚠️ غير مدعوم"
        fi
        echo "- $NAME | $SIZE | آخر تعديل: $MTIME | $STATUS"
        log "- $NAME | $SIZE | آخر تعديل: $MTIME | $STATUS"
    done
    echo "عدد السكربتات في $DIR: $COUNT"
    log "عدد السكربتات في $DIR: $COUNT"
    echo "-----------------------------------"
}

# --- تنفيذ ---
check_dir "$CORE_DIR"
check_dir "$MODULES_DIR"

echo "✅ انتهى فحص المنظومة. سجل كامل موجود في $LOG_FILE"
