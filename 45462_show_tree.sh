#!/bin/bash

ROOT_DIR="${1:-sovereign_system}"  # المسار الجذري للمنظومة

echo "🌳 الهيكل الشجري للمنظومة: $ROOT_DIR"
tree -C -L 4 "$ROOT_DIR"

echo -e "\n📂 اختر ملف لعرض محتواه:"
read FILE_PATH

if [[ -f "$ROOT_DIR/$FILE_PATH" ]]; then
    bat "$ROOT_DIR/$FILE_PATH"
else
    echo "❌ الملف غير موجود أو المسار خطأ."
fi
