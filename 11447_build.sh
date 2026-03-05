#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
mkdir -p bin _logs
# stabilize deps
go env -w GOPROXY=direct >/dev/null 2>&1 || true
go env -w GOSUMDB=off >/dev/null 2>&1 || true
go mod tidy 2>&1 | tee _logs/go_mod_tidy.log
go build -trimpath -ldflags "-s -w" -o bin/forgemindd ./cmd/forgemind
go build -trimpath -ldflags "-s -w" -o bin/forgemindctl ./cmd/forgemindctl
echo "[ok] built"
