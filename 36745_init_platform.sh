#!/usr/bin/env bash
set -e
echo "🧱 Initializing platform..."
mkdir -p data policy commercial security logs
python - <<'PY'
from platform_services.identity import bootstrap_admin
bootstrap_admin()
print("✅ admin/admin ready")
PY
echo "✅ Platform init done"

python - <<'PY'
from security.signing import ensure_key
ensure_key()
print('✅ platform key ready')
PY
