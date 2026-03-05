#!/usr/bin/env python3
# sovereign_main.py - Minimal FastAPI server

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
import os

# إنشاء التطبيق
app = FastAPI(title="Sovereign Hybrid API")

# نقطة النهاية الأساسية
@app.get("/status", response_class=JSONResponse)
async def status():
    return {"status": "API is running"}

# تشغيل الخادم
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    print(f"🚀 FastAPI running at http://127.0.0.1:{port}/status")
    uvicorn.run(app, host="127.0.0.1", port=port)
