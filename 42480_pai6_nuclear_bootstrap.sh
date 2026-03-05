#!/data/data/com.termux/files/usr/bin/bash

set -e

clear
echo "👑 PAI6 — NUCLEAR SMART BOOTSTRAP"
echo "=================================="
sleep 1

echo "🔍 Detecting system..."
uname -a

echo
echo "⚙️ Updating system..."
pkg update -y && pkg upgrade -y

echo
echo "📦 Installing core build packages..."
pkg install -y \
  python \
  git \
  clang \
  make \
  cmake \
  zip \
  unzip \
  wget \
  patchelf \
  libffi \
  openssl \
  ffmpeg \
  libjpeg-turbo \
  libpng

echo
echo "☕ Installing OpenJDK (best available)..."
if pkg search openjdk | grep -q openjdk-25; then
    pkg install -y openjdk-25
elif pkg search openjdk | grep -q openjdk-21; then
    pkg install -y openjdk-21
else
    echo "❌ No OpenJDK package found in Termux repo"
    exit 1
fi

echo
echo "🐍 Installing Python build stack..."
pip install --upgrade pip setuptools wheel

pip install \
  buildozer \
  cython \
  virtualenv \
  pillow \
  psutil \
  requests \
  qrcode \
  flask \
  fastapi \
  uvicorn

echo
echo "🛠️ Verifying toolchain..."

python -V
java -version || true
clang --version || true
cmake --version || true

echo
echo "=================================="
echo "✅ NUCLEAR SMART BOOTSTRAP COMPLETE"
echo "=================================="
