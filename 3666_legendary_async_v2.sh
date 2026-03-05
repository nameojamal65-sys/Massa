#!/data/data/com.termux/files/usr/bin/bash
# ==================================================
# 🚀 Legendary Async System v2 (Speed + Decision)
# ==================================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
APP_FILE="$SYSTEM_DIR/ai_agent_v2.py"
PORT=9000
LOG_FILE="$SYSTEM_DIR/system.log"

mkdir -p $SYSTEM_DIR
cd $SYSTEM_DIR

echo "📦 تثبيت المتطلبات..."
pip install fastapi uvicorn psutil --quiet

echo "🧠 إنشاء محرك Async + Decision Engine..."

cat > $APP_FILE << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import asyncio
import psutil
import time
import logging

# ================= Logging =================
logging.basicConfig(
    filename="system.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

app = FastAPI(title="Legendary Engine v2")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

start_time = time.time()

# ================= Decision Engine =================
def classify_input(text: str):
    if "خطأ" in text:
        return "error_case"
    elif "تحليل" in text:
        return "analysis_case"
    elif "احصائيات" in text:
        return "metrics_case"
    return "general_case"

async def process_case(case: str, text: str):
    await asyncio.sleep(0)
    if case == "error_case":
        return f"⚠ تم رصد حالة خطأ: {text}"
    elif case == "analysis_case":
        return f"📊 تحليل مبدئي للنص: {text}"
    elif case == "metrics_case":
        return {
            "cpu": psutil.cpu_percent(),
            "memory": psutil.virtual_memory().percent
        }
    return f"✅ معالجة عامة: {text}"

# ================= API =================

@app.get("/")
async def root():
    return {"status": "Legendary Engine v2 Running"}

@app.get("/analyze")
async def analyze(q: str):
    case = classify_input(q)
    result = await process_case(case, q)
    logging.info(f"Input: {q} | Case: {case}")
    return {"input": q, "case": case, "result": result}

@app.get("/metrics")
async def metrics():
    uptime = round(time.time() - start_time, 2)
    return {
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "uptime_seconds": uptime
    }

@app.get("/health")
async def health():
    return JSONResponse(status_code=200, content={"health": "OK"})
EOF

echo "🛑 إيقاف أي نسخة سابقة..."
pkill -f uvicorn >/dev/null 2>&1

echo "🚀 تشغيل النظام v2 ..."
nohup uvicorn ai_agent_v2:app \
    --host 0.0.0.0 \
    --port $PORT \
    --workers 1 \
    > $SYSTEM_DIR/server.log 2>&1 &

sleep 2

echo "====================================="
echo "🔥 Legendary Async System v2 Ready"
echo "🌐 افتح:"
echo "http://127.0.0.1:$PORT"
echo "-------------------------------------"
echo "🧠 اختبار قرار:"
echo "http://127.0.0.1:$PORT/analyze?q=تحليل"
echo "📊 احصائيات:"
echo "http://127.0.0.1:$PORT/metrics"
echo "====================================="	
