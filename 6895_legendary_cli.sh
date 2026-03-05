#!/bin/bash

BASE_DIR=~/Legendary_Dashboard
cd $BASE_DIR || exit

REDIS_HOST="localhost"
REDIS_PORT=6379

# التحقق من تثبيت redis-cli
if ! command -v redis-cli &> /dev/null
then
    echo "⚠️ redis-cli غير مثبت. تثبته أولاً:"
    echo "pkg install redis"
    exit
fi

echo "🛰 Legendary V11 CLI Control"
echo "══════════════════════════"
echo "1️⃣ Start API Server"
echo "2️⃣ Stop API Server"
echo "3️⃣ Start Worker"
echo "4️⃣ Stop Worker"
echo "5️⃣ List Tasks in Queue"
echo "6️⃣ Push Task to Queue"
echo "7️⃣ Exit"

API_PID_FILE="legendary_api.pid"
WORKER_PID_FILE="legendary_worker.pid"

while true; do
    echo -n "اختَر خيار: "
    read CHOICE
    case $CHOICE in
        1)
            if [ -f "$API_PID_FILE" ]; then
                echo "API Server يعمل بالفعل. PID=$(cat $API_PID_FILE)"
            else
                nohup python3 app.py > legendary_api.log 2>&1 &
                echo $! > $API_PID_FILE
                echo "✅ API Server بدأ. PID=$(cat $API_PID_FILE)"
            fi
            ;;
        2)
            if [ -f "$API_PID_FILE" ]; then
                kill $(cat $API_PID_FILE)
                rm -f $API_PID_FILE
                echo "🛑 API Server توقف."
            else
                echo "❌ API Server غير شغّال."
            fi
            ;;
        3)
            if [ -f "$WORKER_PID_FILE" ]; then
                echo "Worker يعمل بالفعل. PID=$(cat $WORKER_PID_FILE)"
            else
                nohup ./run_worker.sh > legendary_worker.log 2>&1 &
                echo $! > $WORKER_PID_FILE
                echo "✅ Worker بدأ. PID=$(cat $WORKER_PID_FILE)"
            fi
            ;;
        4)
            if [ -f "$WORKER_PID_FILE" ]; then
                kill $(cat $WORKER_PID_FILE)
                rm -f $WORKER_PID_FILE
                echo "🛑 Worker توقف."
            else
                echo "❌ Worker غير شغّال."
            fi
            ;;
        5)
            echo "📂 مهام في الـ Queue:"
            redis-cli -h $REDIS_HOST -p $REDIS_PORT LRANGE legendary_queue:global 0 -1
            ;;
        6)
            echo -n "أدخل المهمة: "
            read TASK
            redis-cli -h $REDIS_HOST -p $REDIS_PORT LPUSH legendary_queue:global "$TASK"
            echo "✅ المهمة أضيفت للـ Queue."
            ;;
        7)
            echo "👋 خروج..."
            exit
            ;;
        *)
            echo "❌ خيار غير صالح."
            ;;
    esac
done
