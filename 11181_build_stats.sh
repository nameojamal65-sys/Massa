#!/usr/bin/env bash
set -e
FILES=$(find . -type f | wc -l | tr -d ' ')
LINES=$(find . -type f \( -name "*.py" -o -name "*.sh" -o -name "*.yml" -o -name "*.md" -o -name "*.html" -o -name "*.yaml" \) -exec wc -l {} + | tail -n1 | awk '{print $1}')
SIZE=$(du -sh . | awk '{print $1}')
echo "Files: $FILES"
echo "Lines: $LINES"
echo "Dir size: $SIZE"
