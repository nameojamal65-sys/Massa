#!/usr/bin/env bash
set -e
echo "🩺 Platform Doctor: fixing dependencies..."

# Python dependencies
if [ -f "requirements.txt" ]; then
  python -c "import flask, flask_socketio, psutil, PIL, yaml, cryptography, requests" >/dev/null 2>&1 || {
    echo "🐍 Installing requirements..."
    pip install -r requirements.txt
  }
else
  pip install flask flask-socketio psutil pillow pyyaml cryptography requests
fi

mkdir -p logs data policy commercial security

# Ensure signing key if platform signing exists
python - <<'PY'
try:
    from security.signing import ensure_key
    ensure_key()
    print("🔐 Signing key ready")
except Exception as e:
    print("ℹ️ Signing key step skipped:", e)
PY

echo "✅ Doctor done"
