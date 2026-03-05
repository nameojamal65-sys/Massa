#!/bin/bash

echo "🚀 Initializing Legendary Ultimate System..."

BASE_DIR="$HOME/Legendary_Dashboard"
APP_DIR="$BASE_DIR/app_entry"
AGENTS_DIR="$BASE_DIR/agents"
LOG_FILE="$BASE_DIR/legendary_system.log"
DAEMON_FILE="$BASE_DIR/daemon.sh"
RUN_FILE="$BASE_DIR/run_project.sh"

cd "$BASE_DIR" || exit 1

echo "📦 Ensuring package structure..."
touch "$APP_DIR/__init__.py"
touch "$AGENTS_DIR/__init__.py"

echo "🧹 Cleaning cache..."
find "$BASE_DIR" -type d -name "__pycache__" -exec rm -rf {} +

echo "🧠 Creating Control Center..."
cat > "$AGENTS_DIR/control_center.py" <<EOF
class ControlCenter:
    def __init__(self):
        self.agents_status = {}

    def register(self, name):
        self.agents_status[name] = "ACTIVE"

    def stop(self, name):
        self.agents_status[name] = "STOPPED"

    def status(self):
        return self.agents_status

control_center = ControlCenter()
EOF

echo "📊 Injecting logging into main.py..."
if ! grep -q "Legendary System Starting" "$APP_DIR/main.py"; then
cat > "$APP_DIR/main.py" <<EOF
import logging
import os

from agents import ai_agent_async, ai_agent_system, ai_agent_v2, ai_server_agent

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
LOG_PATH = os.path.join(BASE_DIR, "legendary_system.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler()
    ]
)

logging.info("🚀 Legendary Dashboard Starting")

print("🟢 Agent System يعمل الآن")
print("🟢 Agent V2 يعمل الآن")
print("🟢 Agent Async يعمل الآن")
print("🟢 Agent Server يعمل الآن")
EOF
fi

echo "⚙️ Creating run_project.sh..."
cat > "$RUN_FILE" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")"
python3 -m app_entry.main
EOF

chmod +x "$RUN_FILE"

echo "🛰 Creating daemon.sh..."
cat > "$DAEMON_FILE" <<EOF
#!/bin/bash
BASE_DIR="\$(dirname "\$0")"
LOG_FILE="\$BASE_DIR/legendary.log"

cd "\$BASE_DIR"

echo "🚀 Starting Legendary Daemon..."
nohup python3 -m app_entry.main >> "\$LOG_FILE" 2>&1 &
echo \$! > legendary.pid
echo "✅ Running in background. PID stored."
EOF

chmod +x "$DAEMON_FILE"

echo "🏁 System Ready."

echo ""
echo "▶️ تشغيل عادي:"
echo "$RUN_FILE"
echo ""
echo "🛰 تشغيل دائم (Daemon):"
echo "$DAEMON_FILE"
echo ""
echo "🛑 لإيقاف الديمون:"
echo "kill \$(cat legendary.pid)"
