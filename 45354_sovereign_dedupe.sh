#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_build_workspace"
ARCHIVE="$HOME/sovereign_archive_duplicates_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE"

echo "🛡️  DEDUPLICATION: Archiving duplicate folders..."
echo "Root: $ROOT"
echo "Archive: $ARCHIVE"
echo "--------------------------------------"

cd "$ROOT"

# Find duplicate folder names ignoring numbers in parentheses
for dir in $(ls -1); do
    base=$(echo "$dir" | sed -E 's/ \([0-9]+\)$//')
    matches=$(ls -d "$base"* 2>/dev/null | grep -v "^$dir$" || true)
    if [ ! -z "$matches" ]; then
        for dup in $matches; do
            echo "📦 Moving duplicate: $dup"
            mv "$dup" "$ARCHIVE/"
        done
    fi
done

echo ""
echo "✅ Deduplication complete. Duplicates saved at: $ARCHIVE"
echo "Remaining folders:"
ls -1
