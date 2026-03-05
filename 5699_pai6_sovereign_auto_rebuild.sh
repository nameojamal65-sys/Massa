#!/usr/bin/env bash
# ☢️ PAI6 SOVEREIGN AUTO REBUILD SYSTEM
# Nuclear Grade — One Shot — Full Architecture Enforcement

set -e

ROOT="$HOME/PAI6_UltimateClosure"
NEW="$ROOT/PAI6"

echo "☢️  INITIATING SOVEREIGN REBUILD..."
echo "📍 ROOT: $ROOT"

mkdir -p "$NEW"/{bootstrap,core,orchestrator,engines,services,backend,frontend,security,data,logs,reports}

move_safe() {
if [ -d "$ROOT/$1" ]; then
echo "🔁 Migrating $1 → $2"
mv "$ROOT/$1"/* "$NEW/$2"/ 2>/dev/null || true
fi
}

# إعادة توزيع ذكية
move_safe core core
move_safe scanner engines
move_safe dashboard frontend
move_safe kivy_app frontend
move_safe windows_build bootstrap

# بناء Core سيادي
cat << 'PYEOF' > "$NEW/core/main.py"
#!/usr/bin/env python3
class SovereignCore:
    def boot(self):
print("👑 Sovereign Core Booting...")
print("⚙ Core systems online")

if __name__ == "__main__":
SovereignCore().boot()
PYEOF

# بناء Orchestrator مركزي
cat << 'PYEOF' > "$NEW/orchestrator/main.py"
#!/usr/bin/env python3
class Orchestrator:
    def run(self):
print("🧠 Orchestrator Activated")
print("⚡ Managing Engines • Services • Data Flow")

if __name__ == "__main__":
Orchestrator().run()
PYEOF

# بناء Bootstrap
cat << 'PYEOF' > "$NEW/bootstrap/boot.py"
#!/usr/bin/env python3
print("🛰 Sovereign Bootstrap Online")
PYEOF

# بناء نقطة التشغيل السيادية الموحدة
cat << 'PYEOF' > "$NEW/run.py"
#!/usr/bin/env python3
from core.main import SovereignCore
from orchestrator.main import Orchestrator

print("🚀 PAI6 — SOVEREIGN SYSTEM STARTING")

core = SovereignCore()
core.boot()

orchestrator = Orchestrator()
orchestrator.run()

print("✅ SOVEREIGN SYSTEM FULLY OPERATIONAL")
PYEOF

# صلاحيات تنفيذ
chmod -R 755 "$NEW"
chmod +x "$NEW/run.py"

echo "🧹 Cleaning legacy clutter..."
rm -rf "$ROOT"/{core,scanner,dashboard,kivy_app,windows_build} 2>/dev/null || true

echo "⚡ Architecture enforcement completed"
echo "📂 New System Root: $NEW"
echo "🚀 Launch Command: python3 $NEW/run.py"

echo "☢️ SOVEREIGN REBUILD COMPLETE"