#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Usage:
#   ./build_termux.sh /sdcard/Download/forgemind_clean_fixed_v2.zip
# Or run inside extracted repo root.

ZIP="${1:-}"
WORKDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/forgemind_build"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }

need go

if [[ -n "$ZIP" ]]; then
  need unzip
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR"
  unzip -q "$ZIP" -d "$WORKDIR"
  cd "$WORKDIR"
  # flatten single-root folder if present
  shopt -s nullglob
  roots=(*)
  if [[ ${#roots[@]} -eq 1 && -d "${roots[0]}" ]]; then
    cd "${roots[0]}"
  fi
fi

# Normalize CRLF if needed
if command -v dos2unix >/dev/null 2>&1; then
  find . -type f \( -name "*.go" -o -name "*.md" -o -name "*.json" \) -print0 | xargs -0 dos2unix >/dev/null 2>&1 || true
fi

export CGO_ENABLED=0
export GOOS=android

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) export GOARCH=arm64 ;;
  armv7l|armv8l) export GOARCH=arm ;;
  x86_64) export GOARCH=amd64 ;;
  *) echo "Unknown arch: $ARCH"; exit 1 ;;
esac

mkdir -p out
go test ./... -count=1
go vet ./...

go build -trimpath -ldflags="-s -w" -o out/forgemind_android_${GOARCH} ./cmd/forgemind
go build -trimpath -ldflags="-s -w" -o out/forgemindctl_android_${GOARCH} ./cmd/forgemindctl

# checksums
cd out
sha256sum * > checksums.sha256
echo "Built binaries in $(pwd)"
