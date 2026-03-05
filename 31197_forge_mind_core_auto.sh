#!/bin/bash
# ==============================================
# ForgeMind CORE AUTO BUILDER — FINAL
# Author: Zaeem
# Purpose: Auto build Go binaries + collect Python + scripts + archive
# ==============================================

SRC="$HOME/ForgeMind_DRIVE"
OUT="$HOME/sovereign_core_bin"
ARCHIVE="$HOME/sovereign_core_bin.tar.gz"
LOG="$HOME/sovereign_core_bin_log.txt"

rm -rf "$OUT" "$ARCHIVE" "$LOG"
mkdir -p "$OUT"

echo "ForgeMind CORE Auto Packager Log" >> "$LOG"
echo "Start: $(date)" >> "$LOG"
echo "Source directory: $SRC" >> "$LOG"
echo "Output directory: $OUT" >> "$LOG"
echo "------------------------------------" >> "$LOG"

# Build Go binaries (auto detect)
echo "Building Go binaries..." >> "$LOG"
find "$SRC" -type f -name "main.go" ! -path "*/test/*" ! -path "*/tmp/*" | while read MAIN; do
    BIN_NAME=$(basename $(dirname "$MAIN"))
    BIN_PATH="$OUT/$BIN_NAME"
    echo "Building $BIN_NAME..." >> "$LOG"
    go build -o "$BIN_PATH" "$MAIN" >> "$LOG" 2>&1

    if [ $? -eq 0 ]; then
        echo "Built: $BIN_PATH" >> "$LOG"
    else
        echo "FAILED: $BIN_NAME" >> "$LOG"
    fi
done

# Copy shell scripts + env
echo "Copying shell + env files..." >> "$LOG"
find "$SRC" -type f \( -name "*.sh" -o -name "*.env.example" \) \
    ! -path "*/test/*" ! -path "*/tmp/*" | while read FILE; do
    REL="${FILE#$SRC/}"
    DEST="$OUT/$REL"
    mkdir -p "$(dirname "$DEST")"
    cp -a "$FILE" "$DEST"
    echo "Copied: $REL" >> "$LOG"
done

# Copy Python backend
echo "Copying Python backend..." >> "$LOG"
find "$SRC" -type f -name "*.py" \
    ! -path "*/test/*" ! -path "*/tmp/*" | while read FILE; do
    REL="${FILE#$SRC/}"
    DEST="$OUT/$REL"
    mkdir -p "$(dirname "$DEST")"
    cp -a "$FILE" "$DEST"
    echo "Copied Python: $REL" >> "$LOG"
done

# Create archive
TOTAL_SIZE=$(du -sh "$OUT" | cut -f1)
tar -czf "$ARCHIVE" -C "$OUT" .

echo "------------------------------------" >> "$LOG"
echo "Total size: $TOTAL_SIZE" >> "$LOG"
echo "Archive: $ARCHIVE" >> "$LOG"
echo "End: $(date)" >> "$LOG"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ BUILD COMPLETE"
echo "📦 Binary archive: $ARCHIVE"
echo "📄 Log: $LOG"
echo "💾 Output size: $TOTAL_SIZE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
