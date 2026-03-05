from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import psutil, time, asyncio

app = FastAPI(title="Legendary AI Engine v6 Realtime")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

start_time = time.time()

async def ai_model(text: str):
    await asyncio.sleep(0.3)
    return f"🧠 AI Realtime Response to: {text}"

@app.get("/")
async def root():
    return {"status": "Legendary AI v6 Realtime Running"}

@app.get("/metrics")
async def metrics():
    return {
        "cpu": psutil.cpu_percent(),
        "memory": psutil.virtual_memory().percent,
        "uptime": round(time.time() - start_time, 2)
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        try:
            data = await websocket.receive_text()
            response = await ai_model(data)
            await websocket.send_text(response)
        except:
            break
