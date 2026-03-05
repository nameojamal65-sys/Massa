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
