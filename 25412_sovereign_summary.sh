#!/bin/bash

echo "=================================="
echo "🚀 SOVEREIGN EXECUTIVE SUMMARY"
echo "=================================="

echo ""
echo "⏳ Analyzing project..."

# Exclude heavy folders
TOTAL_FILES=$(find . -path ./node_modules -prune -o -type f -print | wc -l)
TOTAL_DIRS=$(find . -path ./node_modules -prune -o -type d -print | wc -l)

TOTAL_LINES=$(find . -path ./node_modules -prune -o \
  -type f \( -name "*.js" -o -name "*.ts" \) -print0 \
  | xargs -0 cat 2>/dev/null | wc -l)

PROJECT_SIZE=$(du -sh . | awk '{print $1}')

NODE_VERSION=$(node -v 2>/dev/null)
NPM_VERSION=$(npm -v 2>/dev/null)
ARCH=$(uname -m)

echo ""
echo "📦 Project Size:  $PROJECT_SIZE"
echo "📄 Total Files:   $TOTAL_FILES"
echo "📁 Total Folders: $TOTAL_DIRS"
echo "📜 JS/TS Lines:   $TOTAL_LINES"
echo ""
echo "🧠 Node:          ${NODE_VERSION:-Not Found}"
echo "📦 NPM:           ${NPM_VERSION:-Not Found}"
echo "🏗 Arch:           $ARCH"
echo ""
echo "=================================="
echo "🔥 Summary Complete"
echo "=================================="

