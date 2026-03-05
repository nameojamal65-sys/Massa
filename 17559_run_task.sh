#!/bin/bash
# 🦅 Sovereign Task Runner
# تشغيل مهمة AI Core ومتابعة البناء تلقائيًا

# مسار API Core
API_URL="http://127.0.0.1:8000"

# مهمة اليوم (غير الوصف بما تريد)
TASK_FILE="$HOME/sovereign_api/tasks/vehicle_diagnostics.json"

# إرسال المهمة
echo "🚀 إرسال المهمة للمنظومة..."
TASK_ID=$(curl -s -X POST "$API_URL/run_task" \
        -H "Content-Type: application/json" \
        -d @"$TASK_FILE" | jq -r '.task_id')

if [ -z "$TASK_ID" ] || [ "$TASK_ID" == "null" ]; then
    echo "❌ فشل إنشاء المهمة."
    exit 1
fi

echo "✅ المهمة أُرسلت. Task ID: $TASK_ID"

# متابعة المهمة
echo "⏳ متابعة تقدم المهمة..."
while true; do
    STATUS=$(curl -s "$API_URL/task_status/$TASK_ID")
    echo "$STATUS"
    if [[ "$STATUS" == *"completed"* ]]; then
        echo "✅ المهمة اكتملت."
        break
    elif [[ "$STATUS" == *"failed"* ]]; then
        echo "❌ فشلت المهمة."
        exit 1
    fi
    sleep 10
done

# استخراج الملفات النهائية
OUTPUT_DIR="$HOME/sovereign_api/output"
LOG_FILE="$HOME/sovereign_api/final_build.log"

echo "📁 الملفات المبنية:"
mkdir -p "$OUTPUT_DIR"
find "$OUTPUT_DIR" -type f -exec ls -lh {} \; | tee "$LOG_FILE"

TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | awk '{print $1}')
NUM_FILES=$(find "$OUTPUT_DIR" -type f | wc -l)

echo "📁 عدد الملفات: $NUM_FILES" | tee -a "$LOG_FILE"
echo "💾 الحجم الإجمالي: $TOTAL_SIZE" | tee -a "$LOG_FILE"
echo "✅ التقرير مكتمل. يمكنك مراجعة اللوج هنا: $LOG_FILE"
