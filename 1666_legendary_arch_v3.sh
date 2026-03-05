#!/data/data/com.termux/files/usr/bin/bash
# ==================================================
# 🏗 Legendary System v3 - Clean Architecture
# ==================================================

BASE="$HOME/Legendary_Dashboard/app"
PORT=9000

echo "📦 تثبيت المتطلبات..."
pip install fastapi uvicorn psutil --quiet

echo "📁 إنشاء الهيكل المعماري..."
mkdir -p $BASE/core
mkdir -p $BASE/services
mkdir -p $BASE/utils

# ================= LOGGER =================
cat > $BASE/utils/logger.py << 'EOF'
import logging
logging.basicConfig(
    filename="system.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("LegendaryLogger")
EOF

# ================= DECISION ENGINE =================
cat > $BASE/core/decision_engine.py << 'EOF'
def classify(text: str):
    if "خطأ" in text:
        return "error"
    elif "تحليل" in text:
        return "analysis"
    elif "احصائيات" in text:
        return "metrics"
    return "general"
EOF

# ================= PROCESSOR =================
cat > $BASE/core/processor.py << 'EOF'
import asyncio

async def process(case: str, text: str):
    await asyncio.sleep(0)
    if case == "error":
        return f"⚠ تم اكتشاف خطأ: {text}"
    elif case == "analysis":
        return f"📊 تحليل للنص: {text}"
    return f"✅ معالجة عامة: {text}"
EOF

# ================= METRICS SERVICE =================
cat > $BASE/services/metrics_service.py << 'EOF'
import psutil
import time

start_time = time.time()

def get_metrics():
    return {
        "cpu": psutil.cpu_percent(),
        "memory": psutil.virtual_memory().percent,
        "uptime": round(time.time() - start_time, 2)
    }
EOF

# ================= MAIN API =================
cat > $BASE/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.decision_engine import classify
from core.processor import process
from services.metrics_service import get_metrics
from utils.logger import logger

app = FastAPI(title="Legendary Engine v3")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"status": "Legendary Engine v3 Running"}

@app.get("/analyze")
async def analyze(q: str):
    case = classify(q)
    result = await process(case, q)
    logger.info(f"Input: {q} | Case: {case}")
    return {"case": case, "result": result}

@app.get("/metrics")
async def metrics():
    return get_metrics()
EOF

echo "🛑 إيقاف أي نسخة سابقة..."
pkill -f uvicorn >/dev/null 2>&1

echo "🚀 تشغيل النظام v3..."
cd $BASE
nohup uvicorn main:app --host 0.0.0.0 --port $PORT > server.log 2>&1 &

sleep 2

echo "====================================="
echo "🔥 Legendary Architecture v3 Ready"
echo "🌐 http://127.0.0.1:$PORT"
echo "====================================="
