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
