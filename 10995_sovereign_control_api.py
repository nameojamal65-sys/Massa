from fastapi import FastAPI
import uvicorn
import socket
import time

app = FastAPI(title="Sovereign Control Core")


@app.get("/")
def root():
    return {
        "status": "ONLINE",
        "node": "SOVEREIGN_PHONE",
        "time": time.ctime(),
        "ip": socket.gethostbyname(socket.gethostname())
    }


@app.get("/ping")
def ping():
    return {"pong": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9200)
