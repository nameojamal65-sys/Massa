#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "[fm] PWD=$(pwd)"

# 0) تأكد من الجذر
if [[ ! -f go.mod ]] || [[ ! -d scripts/termux ]]; then
  echo "[fm] ERROR: انت مش داخل جذر المشروع."
  echo "[fm] لازم تكون داخل مجلد فيه go.mod و scripts/termux"
  exit 2
fi

# 1) تحديث وتركيب الأدوات الأساسية
echo "[fm] pkg update/upgrade..."
pkg update -y
pkg upgrade -y || true

echo "[fm] install toolchain + libs..."
pkg install -y \
  git curl wget tar unzip findutils coreutils sed grep gawk \
  make clang pkg-config \
  openssl-tool sqlite \
  golang nodejs-lts python rust

# 2) pnpm (لـ UI)
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[fm] install pnpm..."
  npm i -g pnpm
fi

# 3) صلاحيات السكربتات
chmod +x scripts/termux/*.sh 2>/dev/null || true

# 4) حل مشكلة pnpm: ignored build scripts (مثل esbuild)
# (هذا الشيء يسبب build ناقص أو مشاكل لاحقة)
if [[ -d ui ]] && [[ -f ui/pnpm-lock.yaml ]]; then
  echo "[fm] UI deps install..."
  (cd ui && pnpm install)
  echo "[fm] pnpm approve-builds (best effort)..."
  (cd ui && pnpm approve-builds || true)
fi

# 5) Go network fallbacks (إذا الشبكة صعبة)
echo "[fm] go env fallbacks..."
go env -w GOPROXY=direct || true
go env -w GOSUMDB=off || true

# 6) حل مشكلة missing go.sum
echo "[fm] go mod tidy..."
go mod tidy

# 7) Build (يفضل سكربت المشروع)
mkdir -p _logs
echo "[fm] build..."
if [[ -x scripts/termux/build.sh ]]; then
  bash scripts/termux/build.sh 2>&1 | tee _logs/build_setup.log
else
  mkdir -p bin
  go build -trimpath -ldflags "-s -w" -o bin/forgemindd ./cmd/forgemind 2>&1 | tee _logs/build_setup.log
  if [[ -d cmd/forgemindctl ]]; then
    go build -trimpath -ldflags "-s -w" -o bin/forgemindctl ./cmd/forgemindctl 2>&1 | tee -a _logs/build_setup.log
  fi
fi

# 8) Verify: هل فعلاً انبنى باينري؟
echo "[fm] verify..."
ls -la bin || true
if [[ -x bin/forgemindd ]]; then
  echo "[fm] ✅ BUILT: bin/forgemindd"
  file bin/forgemindd || true
else
  echo "[fm] ❌ NOT BUILT: bin/forgemindd missing"
  echo "[fm] See _logs/build_setup.log"
  exit 1
fi

echo "[fm] done."
