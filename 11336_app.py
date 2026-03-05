from fastapi import FastAPI
from orchestrator.orchestrator import execute
from doctor.system_doctor import health

app = FastAPI()


@app.get("/")
def root():
    return {"status": "Sovereign Core Online"}


@app.get("/health")
def h():
    return health()


@app.post("/run")
def run(task: str, lang: str = "en"):
    return execute(task, lang)
