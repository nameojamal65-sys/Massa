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
