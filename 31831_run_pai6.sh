#!/bin/bash
# ==============================
# PAI6 Permissions & Launch Only
# ==============================

ROOT="$HOME/PAI6_UltimateClosure"

# ------------------------------
# 1️⃣ ضبط الصلاحيات على المجلدات والملفات
# ------------------------------
for folder in core dashboard scanner kivy_app windows_build; do
    if [ -d "$ROOT/$folder" ]; then
        chmod -R 755 "$ROOT/$folder"
    fi
done

find "$ROOT" -type f -name "*.sh" -exec chmod +x {} \;
find "$ROOT" -type f -name "*.py" -exec chmod 644 {} \;
find "$ROOT" -type f -name "*.json" -exec chmod 644 {} \;
find "$ROOT" -type f -name "*.kv" -exec chmod 644 {} \;

# ------------------------------
# 2️⃣ تشغيل النواة
# ------------------------------
CORE_SCRIPT="$ROOT/core/core.py"

if [ -f "$CORE_SCRIPT" ]; then
    echo "🚀 Launching Sovereign Core..."
    python3 "$CORE_SCRIPT" &
    echo "✅ Sovereign Core launched"
else
    echo "⚠️ Core script not found: $CORE_SCRIPT"
fi
