#!/bin/bash
# تشغيل Trimex من Home مع البيئة الصحيحة

echo "🚀 Starting Trimex environment..."

# انتقل لمجلد تثبيت Trimex (عدل المسار إذا كان مختلف)
TRIMEX_PATH="$HOME/Trimex"
PYTHON_ENV="$TRIMEX_PATH/env/bin/python"  # لو عندك env افتراضي

# تحقق من وجود سكربت الإعداد
AUTOSCRIPT="$HOME/trimex_autosetup.py"
if [ ! -f "$AUTOSCRIPT" ]; then
    echo "❌ Script trimex_autosetup.py غير موجود في $HOME"
    exit 1
fi

# شغّل Trimex Core أو أي خدمة لازمة
echo "✅ Launching Trimex Core..."
"$PYTHON_ENV" "$AUTOSCRIPT"

echo "✅ Trimex setup script executed successfully!"
