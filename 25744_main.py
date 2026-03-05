from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import psutil
import time

app = FastAPI(title="PAI6 Sovereign Control")


@app.get("/status")
def status():
    return {
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage('/').percent,
        "time": time.ctime()
    }


@app.get("/")
def dashboard():
    return HTMLResponse(open("web/index.html").read())
