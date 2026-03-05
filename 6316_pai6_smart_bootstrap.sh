#!/data/data/com.termux/files/usr/bin/bash

set -e

clear
echo "👑 PAI6 — SMART DEPENDENCY BOOTSTRAP"
echo "==================================="
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
if pkg search openjdk | grep -q openjdk-21; then
    pkg install -y openjdk-21
elif pkg search openjdk | grep -q openjdk-20; then
    pkg install -y openjdk-20
elif pkg search openjdk | grep -q openjdk-17; then
    pkg install -y openjdk-17
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
echo "==================================="
echo "✅ SMART BOOTSTRAP COMPLETE"
echo "==================================="
