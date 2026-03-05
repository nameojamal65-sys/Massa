#!/bin/bash
# sovereign_tree.sh - يعرض مجلد المنظومة بشكل شجري

# مجلد المنظومة (تقدر تغيّره حسب مكان الملفات)
ROOT_DIR="${1:-$HOME/sovereign_system}"

# التحقق من وجود المجلد
if [ ! -d "$ROOT_DIR" ]; then
    echo "❌ المجلد غير موجود: $ROOT_DIR"
    exit 1
fi

# دالة لطباعة الشجرة
print_tree() {
    local prefix="$1"
    local path="$2"
    local files=("$path"/*)
    local count=${#files[@]}

    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local base="$(basename "$file")"
        local connector="├──"

        # آخر عنصر
        if [ $i -eq $((count - 1)) ]; then
            connector="└──"
        fi

        # طباعة الملف أو المجلد
        if [ -d "$file" ]; then
            echo "${prefix}${connector} [D] $base"
            # استدعاء الدالة للمجلدات الفرعية
            print_tree "${prefix}│   " "$file"
        else
            echo "${prefix}${connector} [F] $base"
        fi
    done
}

echo "📂 شجرة الملفات لـ: $ROOT_DIR"
print_tree "" "$ROOT_DIR"
