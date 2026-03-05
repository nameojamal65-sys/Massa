#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/sovereign_system"
TARGET_LOG="$BASE/forgmind_smart_digest_1770761807.txt"

echo "===== Sovereign Cleanup Utility ====="
echo ""

echo "[1] Checking main directory size..."
du -sh "$BASE"
echo ""

# --- Step 1: Handle giant log file ---
if [ -f "$TARGET_LOG" ]; then
    SIZE=$(du -h "$TARGET_LOG" | cut -f1)
    echo "[2] Found large log file: $SIZE"

    echo "Preview (first 5 lines):"
    head -5 "$TARGET_LOG"
    echo ""
    echo "Preview (last 5 lines):"
    tail -5 "$TARGET_LOG"
    echo ""

    read -p "Backup & compress before delete? (y/n): " BACKUP

    if [ "$BACKUP" = "y" ]; then
        echo "Compressing..."
        gzip "$TARGET_LOG"
        echo "Compressed to: $TARGET_LOG.gz"
    else
        echo "Deleting..."
        rm -f "$TARGET_LOG"
        echo "Deleted."
    fi
fi

echo ""

# --- Step 2: Remove duplicate OpenCV SDK ---
echo "[3] Cleaning duplicate OpenCV SDK..."
find "$BASE/apk_build" -type d -name "OpenCV-android-sdk" -exec rm -rf {} +
echo "OpenCV cleaned."
echo ""

# --- Step 3: Remove apk_build artifacts (optional) ---
read -p "Remove full apk_build directory? (y/n): " APKDEL
if [ "$APKDEL" = "y" ]; then
    rm -rf "$BASE/apk_build"
    echo "apk_build removed."
fi

echo ""

# --- Step 4: Clean logs & tmp ---
echo "[4] Cleaning logs and tmp..."
rm -rf "$BASE/logs"/*
rm -rf "$BASE/tmp"/*
rm -rf "$BASE/task_logs"/*
echo "Logs cleaned."
echo ""

# --- Step 5: Clean node_modules if exists ---
if [ -d "$BASE/node_modules" ]; then
    echo "[5] Removing node_modules..."
    rm -rf "$BASE/node_modules"
    echo "node_modules removed."
fi

echo ""

echo "===== Final Size ====="
du -sh "$BASE"

echo "Cleanup Complete 🚀"
