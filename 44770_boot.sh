#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo "🚀 Booting Sovereign Core Autonomous System..."

# 1️⃣ Doctor Master
if [ -f ./sc_doctor_master.sh ]; then
    ./sc_doctor_master.sh
else
    echo "⚠️ Warning: sc_doctor_master.sh missing"
fi

# 2️⃣ ULTRA Store
if [ -f ./ultra_store.sh ]; then
    ./ultra_store.sh
else
    echo "⚠️ Warning: ultra_store.sh missing"
fi

# 3️⃣ Sovereign GRID
if [ -f ./sovereign_grid.sh ]; then
    ./sovereign_grid.sh
else
    echo "⚠️ Warning: sovereign_grid.sh missing"
fi

# 4️⃣ Autonomous Core
if [ -f ./autonomous_core.sh ]; then
    ./autonomous_core.sh
else
    echo "⚠️ Warning: autonomous_core.sh missing"
fi

echo "✅ Sovereign Core Fully Online"
echo "🌐 Dashboard: http://127.0.0.1:8080"
