#!/bin/bash
# 🏗 Legendary Dashboard Full Setup Script
# إنشاء الهيكل، الملفات، وتهيئة السكريبتات الأساسية

BASE_DIR=~/Legendary_Dashboard
echo "🚀 إعداد المشروع في $BASE_DIR"

# إنشاء المجلدات الرئيسية
mkdir -p $BASE_DIR/app_entry
mkdir -p $BASE_DIR/agents
mkdir -p $BASE_DIR/backend
mkdir -p $BASE_DIR/frontend
mkdir -p $BASE_DIR/legacy_frontend
mkdir -p $BASE_DIR/android_app
mkdir -p $BASE_DIR/infra/logs
mkdir -p $BASE_DIR/scripts

echo "📁 المجلدات الأساسية تم إنشاؤها"

# إنشاء ملفات Agents الأساسية
cat > $BASE_DIR/agents/ai_agent_system.py <<'EOF'
def run():
    print("🟢 Agent System يعمل الآن")
EOF

cat > $BASE_DIR/agents/ai_agent_v2.py <<'EOF'
def run():
    print("🟢 Agent V2 يعمل الآن")
EOF

cat > $BASE_DIR/agents/ai_agent_async.py <<'EOF'
def run_async():
    print("🟢 Agent Async يعمل الآن")
EOF

cat > $BASE_DIR/agents/ai_server_agent.py <<'EOF'
def run_server():
    print("🟢 Agent Server يعمل الآن")
EOF

echo "🤖 ملفات Agents جاهزة"

# إنشاء ملف main.py في app_entry
cat > $BASE_DIR/app_entry/main.py <<'EOF'
from agents import ai_agent_async, ai_agent_system, ai_agent_v2, ai_server_agent

def main():
    print("🚀 تشغيل Legendary Dashboard")
    ai_agent_system.run()
    ai_agent_v2.run()
    ai_agent_async.run_async()
    ai_server_agent.run_server()

if __name__ == "__main__":
    main()
EOF

echo "📄 ملف main.py جاهز"

# إنشاء سكريبت التشغيل
cat > $BASE_DIR/run_project.sh <<'EOF'
#!/bin/bash
python3 app_entry/main.py
EOF

chmod +x $BASE_DIR/run_project.sh
echo "▶️ سكريبت التشغيل run_project.sh جاهز"

# إنشاء ملف README
cat > $BASE_DIR/README.md <<'EOF'
# Legendary Dashboard
🚀 مشروع تجريبي لإدارة Agents وواجهة Dashboard
EOF

# إنشاء ملف البيئة
cat > $BASE_DIR/config.env <<'EOF'
API_KEY=YOUR_API_KEY
DEBUG=True
LOG_PATH=./infra/logs/
EOF

echo "✅ كل شيء جاهز! لتشغيل المشروع: ./run_project.sh"
