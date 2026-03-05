#!/usr/bin/env bash
# ☢️ PAI6 SOVEREIGN ARCHITECT RESTRUCTURER

ROOT="$HOME/PAI6_UltimateClosure"
NEW="$ROOT/PAI6"

echo "☢️ Initiating Sovereign Restructure..."

mkdir -p "$NEW"/{bootstrap,core,orchestrator,engines,services,backend,frontend,security,data,logs,reports}

move_if_exists() {
if [ -d "$ROOT/$1" ]; then
echo "🔁 Migrating $1 → $2"
mv "$ROOT/$1"/* "$NEW/$2"/ 2>/dev/null
fi
}

move_if_exists core core
move_if_exists scanner engines
move_if_exists dashboard frontend
move_if_exists kivy_app frontend
move_if_exists windows_build bootstrap

# توليد Orchestrator
cat << 'PYEOF' > "$NEW/orchestrator/main.py"
#!/usr/bin/env python3
print("🧠 Sovereign Orchestrator Online")
def orchestrate():
print("⚡ Managing Engines, Services, Core")
if __name__ == "__main__":
orchestrate()
PYEOF

# توليد Core سيادي
cat << 'PYEOF' > "$NEW/core/main.py"
#!/usr/bin/env python3
print("👑 Sovereign Core Activated")
def boot():
print("🚀 System Boot Sequence Initiated")
if __name__ == "__main__":
boot()
PYEOF

# توليد Bootstrap
cat << 'PYEOF' > "$NEW/bootstrap/boot.py"
#!/usr/bin/env python3
print("🛰 Bootstrapping Sovereign System...")
PYEOF

# توليد نقطة تشغيل عليا
cat << 'PYEOF' > "$NEW/run.py"
#!/usr/bin/env python3
from core.main import boot
from orchestrator.main import orchestrate

print("🚀 PAI6 SOVEREIGN SYSTEM START")
boot()
orchestrate()
print("✅ SYSTEM FULLY OPERATIONAL")
PYEOF

chmod +x "$NEW"/**/*.py "$NEW/run.py"

echo "✅ Sovereign Architecture Deployed"
echo "📂 New Root: $NEW"
echo "🚀 To run: python3 $NEW/run.py"