#!/bin/bash
# legendary_cli_v11.sh
# CLI للتحكم الكامل في Legendary V11 Termux Edition

BASE_DIR=~/Legendary_Dashboard
APP_ENTRY=$BASE_DIR/app_entry
WORKER_SCRIPT=$BASE_DIR/run_worker.sh
API_PID_FILE=$BASE_DIR/api.pid
WORKER_PID_FILE=$BASE_DIR/worker.pid

start_api() {
    echo "🚀 تشغيل API Server..."
    if [ -f "$API_PID_FILE" ]; then
        echo "⚠️ API Server يبدو أنه يعمل بالفعل. PID=$(cat $API_PID_FILE)"
    else
        # تشغيل uvicorn مع إصلاح Pydantic 2.12
        python3 - <<PYTHON_EOF &
import uvicorn
import os
os.environ["PYTHONPATH"] = f"{os.environ.get('PYTHONPATH', '')}:{os.path.expanduser(BASE_DIR)}"
uvicorn.run("legendary.api.server:app", host="0.0.0.0", port=8000)
PYTHON_EOF
        echo $! > "$API_PID_FILE"
        echo "🟢 API Server بدأ PID=$(cat $API_PID_FILE)"
    fi
}

stop_api() {
    if [ -f "$API_PID_FILE" ]; then
        kill $(cat $API_PID_FILE) && rm "$API_PID_FILE"
        echo "🛑 API Server متوقف"
    else
        echo "⚠️ API Server غير شغّال"
    fi
}

start_worker() {
    echo "🟢 تشغيل Worker..."
    if [ -f "$WORKER_PID_FILE" ]; then
        echo "⚠️ Worker يعمل بالفعل PID=$(cat $WORKER_PID_FILE)"
    else
        bash "$WORKER_SCRIPT" &
        echo $! > "$WORKER_PID_FILE"
        echo "🟢 Worker بدأ PID=$(cat $WORKER_PID_FILE)"
    fi
}

stop_worker() {
    if [ -f "$WORKER_PID_FILE" ]; then
        kill $(cat $WORKER_PID_FILE) && rm "$WORKER_PID_FILE"
        echo "🛑 Worker متوقف"
    else
        echo "⚠️ Worker غير شغّال"
    fi
}

list_queue() {
    echo "📋 المهام الحالية في Redis Queue:"
    redis-cli LRANGE legendary_tasks 0 -1
}

push_task() {
    read -p "اكتب اسم المهمة: " TASK
    redis-cli RPUSH legendary_tasks "$TASK"
    echo "✅ المهمة '$TASK' أضيفت للـ Queue"
}

while true; do
    echo "🛰 Legendary V11 CLI Control"
    echo "══════════════════════════"
    echo "1️⃣ Start API Server"
    echo "2️⃣ Stop API Server"
    echo "3️⃣ Start Worker"
    echo "4️⃣ Stop Worker"
    echo "5️⃣ List Tasks in Queue"
    echo "6️⃣ Push Task to Queue"
    echo "7️⃣ Exit"
    read -p "اختَر خيار: " OPTION
    case $OPTION in
        1) start_api ;;
        2) stop_api ;;
        3) start_worker ;;
        4) stop_worker ;;
        5) list_queue ;;
        6) push_task ;;
        7) echo "👋 الخروج..."; exit 0 ;;
        *) echo "⚠️ خيار غير صحيح!" ;;
    esac
done
