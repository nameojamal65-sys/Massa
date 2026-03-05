#!/bin/bash
# =========================================
# ForgeMind CORE Binary Packager
# Author: Zaeem
# Purpose: Build Go binaries, copy scripts, create final archive
# =========================================

SRC="$HOME/ForgeMind_DRIVE"
OUT="$HOME/sovereign_core_bin"
ARCHIVE="$HOME/sovereign_core_bin.tar.gz"
LOG="$HOME/sovereign_core_bin_log.txt"

rm -rf "$OUT"
mkdir -p "$OUT"

echo "ForgeMind CORE Binary Packager Log" > "$LOG"
echo "Start: $(date)" >> "$LOG"
echo "Source: $SRC" >> "$LOG"
echo "Output: $OUT" >> "$LOG"
echo "------------------------" >> "$LOG"

echo "Building Go binaries..." >> "$LOG"
for MAIN in $(find "$SRC/cmd" -name "main.go"); do
    BIN_NAME=$(basename $(dirname "$MAIN"))
    BIN_PATH="$OUT/$BIN_NAME"
    echo "Building: $BIN_NAME ..." >> "$LOG"
    go build -o "$BIN_PATH" "$MAIN"
    if [ $? -eq 0 ]; then
        echo "Built: $BIN_PATH" >> "$LOG"
    else
        echo "Error building: $BIN_NAME" >> "$LOG"
    fi
done

echo "Copying shell scripts and env files..." >> "$LOG"
find "$SRC" -type f \( -name "*.sh" -o -name "*.env.example" \) \
    ! -path "*/test/*" ! -path "*/tmp/*" | while read FILE; do
    REL="${FILE#$SRC/}"
    DEST="$OUT/$REL"
    mkdir -p "$(dirname "$DEST")"
    cp -a "$FILE" "$DEST"
    echo "Copied: $REL" >> "$LOG"
done

echo "Copying Python backend files..." >> "$LOG"
find "$SRC" -type f -name "*.py" \
    ! -path "*/test/*" ! -path "*/tmp/*" | while read FILE; do
    REL="${FILE#$SRC/}"
    DEST="$OUT/$REL"
    mkdir -p "$(dirname "$DEST")"
    cp -a "$FILE" "$DEST"
    echo "Copied Python: $REL" >> "$LOG"
done

TOTAL_SIZE=$(du -sh "$OUT" | cut -f1)
tar -czf "$ARCHIVE" -C "$OUT" .
echo "Files copied and binaries built: $(ls $OUT | wc -l)" >> "$LOG"
echo "Total size: $TOTAL_SIZE" >> "$LOG"
echo "Archive created: $ARCHIVE" >> "$LOG"
echo "End: $(date)" >> "$LOG"

echo "ForgeMind CORE Binary Packager finished successfully!"
echo "Check log at: $LOG"
echo "Binary archive: $ARCHIVE"
