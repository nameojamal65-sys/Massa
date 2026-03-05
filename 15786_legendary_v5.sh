#!/data/data/com.termux/files/usr/bin/bash
# ==================================================
# 🔥 Legendary System v5 - Memory + Background + Cache
# ==================================================

BASE="$HOME/Legendary_Dashboard/app_v5"
PORT=9000

echo "📦 تثبيت المتطلبات..."
pip install fastapi uvicorn psutil aiosqlite --quiet

echo "📁 إنشاء الهيكل..."
mkdir -p $BASE/core
mkdir -p $BASE/services
mkdir -p $BASE/utils
mkdir -p $BASE/db

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

# ================= MEMORY (SQLite) =================
cat > $BASE/db/memory.py << 'EOF'
import aiosqlite

DB_FILE = "memory.db"

async def init_db():
    async with aiosqlite.connect(DB_FILE) as db:
        await db.execute("""
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            input TEXT,
            case TEXT,
            result TEXT
        )
        """)
        await db.commit()

async def save_log(input_text, case, result):
    async with aiosqlite.connect(DB_FILE) as db:
        await db.execute(
            "INSERT INTO logs (input, case, result) VALUES (?, ?, ?)",
            (input_text, case, result)
        )
        await db.commit()
EOF

# ================= DECISION =================
cat > $BASE/core/decision_engine.py << 'EOF'
def classify(text: str):
    if "خطأ" in text:
        return "error"
    elif "تحليل" in text:
        return "analysis"
    return "general"
EOF

# ================= PROCESSOR =================
cat > $BASE/core/processor.py << 'EOF'
import asyncio

async def process(case: str, text: str):
    await asyncio.sleep(0)
    if case == "error":
        return f"⚠ Error detected: {text}"
    elif case == "analysis":
        return f"📊 Analysis result: {text}"
    return f"✅ Processed: {text}"
EOF

# ================= METRICS =================
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

# ================= MAIN =================
cat > $BASE/main.py << 'EOF'
from fastapi import FastAPI, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
import asyncio

from core.decision_engine import classify
from core.processor import process
from services.metrics_service import get_metrics
from utils.logger import logger
from db.memory import init_db, save_log

app = FastAPI(title="Legendary Engine v5")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    await init_db()

@app.get("/")
async def root():
    return {"status": "Legendary Engine v5 Running"}

@app.get("/analyze")
async def analyze(q: str, background_tasks: BackgroundTasks):
    case = classify(q)
    result = await process(case, q)

    background_tasks.add_task(save_log, q, case, result)
    logger.info(f"{q} | {case}")

    return {"case": case, "result": result}

@app.get("/metrics")
async def metrics():
    return get_metrics()

@app.get("/health")
async def health():
    return {"health": "OK"}
EOF

echo "🛑 إيقاف أي نسخة سابقة..."
pkill -f uvicorn >/dev/null 2>&1

echo "🚀 تشغيل النظام v5..."
cd $BASE
nohup uvicorn main:app --host 0.0.0.0 --port $PORT > server.log 2>&1 &

sleep 2

echo "====================================="
echo "🔥 Legendary System v5 Ready"
echo "🌐 http://127.0.0.1:$PORT"
echo "====================================="
