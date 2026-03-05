from fastapi import FastAPI
import subprocess

app = FastAPI()

@app.get("/")
def root():
return {"status":"PAI6 Sovereign Core Online"}

@app.get("/health")
def health():
return {"health":"stable","core":"active"}