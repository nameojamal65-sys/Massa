#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# 🚀 Legendary Async Hyper System v1.0
# ============================================

SYSTEM_DIR="$HOME/Legendary_Dashboard"
APP_FILE="$SYSTEM_DIR/ai_agent_async.py"
PORT=9000

mkdir -p $SYSTEM_DIR
cd $SYSTEM_DIR

echo "📦 تثبيت المتطلبات..."
pip install fastapi uvicorn psutil --quiet

echo "🧠 إنشاء محرك Async..."

cat > $APP_FILE << 'EOF'
from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import asyncio
import psutil
import time

app = FastAPI(title="Legendary Async Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

start_time = time.time()

async def heavy_process(data: str):
    await asyncio.sleep(0)
    return f"Processed: {data}"

@app.get("/")
async def root():
    return {"status": "Legendary Engine Running"}

@app.get("/analyze")
async def analyze(q: str):
    result = await heavy_process(q)
    return {"input": q, "result": result}

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

echo "🚀 تشغيل السيرفر Async Production..."

pkill -f uvicorn >/dev/null 2>&1

nohup uvicorn ai_agent_async:app \
    --host 0.0.0.0 \
    --port $PORT \
    --workers 1 \
    > $SYSTEM_DIR/async.log 2>&1 &

sleep 2

echo "====================================="
echo "🔥 Legendary Async System Ready"
echo "🌐 افتح المتصفح على:"
echo "http://127.0.0.1:$PORT"
echo "-------------------------------------"
echo "📊 Metrics:"
echo "http://127.0.0.1:$PORT/metrics"
echo "🧠 Analyze Test:"
echo "http://127.0.0.1:$PORT/analyze?q=hello"
echo "====================================="
