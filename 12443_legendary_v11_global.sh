#!/bin/bash

echo "🚀 Initializing Legendary V11 – Global Cluster"

BASE_DIR=~/Legendary_Dashboard
cd $BASE_DIR || exit

echo "📦 Installing dependencies..."
pkg install redis docker -y
pip install fastapi uvicorn redis python-jose passlib[bcrypt] pydantic[dotenv] --break-system-packages 2>/dev/null
pip install kubernetes --break-system-packages 2>/dev/null

echo "🗄 Creating multi-tenant database config..."
cat > legendary/config.py <<EOF
from pydantic import BaseSettings

class Settings(BaseSettings):
    SECRET_KEY: str = "legendary_super_secret_key_v11"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    MULTI_TENANT_DB_URL: str = "sqlite:///legendary_v11.db"  # لاحقًا يمكن PostgreSQL
settings = Settings()
EOF

echo "🔐 Updating Auth for multi-tenant..."
cat > legendary/api/auth.py <<EOF
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext
from legendary.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

fake_users_db = {
    "admin": {
        "username": "admin",
        "hashed_password": pwd_context.hash("admin123"),
        "tenant": "global"
    }
}

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def authenticate_user(username, password):
    user = fake_users_db.get(username)
    if not user or not verify_password(password, user["hashed_password"]):
        return None
    return user

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
EOF

echo "📨 Redis Queue remains for distributed tasks..."
cat > legendary/utils/queue.py <<EOF
import redis
from legendary.config import settings

r = redis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT)

def push_task(task, tenant="global"):
    r.lpush(f"legendary_queue:{tenant}", task)

def pop_task(tenant="global"):
    return r.rpop(f"legendary_queue:{tenant}")
EOF

echo "⚙️ Updating Worker for multi-tenant..."
cat > legendary/worker.py <<EOF
import time
from legendary.utils.queue import pop_task

print("🛰 Legendary Worker V11 started...")

TENANTS=("global") # لاحقًا يمكن قراءتها من DB

while True:
    for tenant in TENANTS:
        task = pop_task(tenant)
        if task:
            print(f"🔥 Processing task for {tenant}: {task.decode()}")
    time.sleep(2)
EOF

echo "🌐 Updating API Server for multi-tenant endpoints..."
cat > legendary/api/server.py <<EOF
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from legendary.api.auth import authenticate_user, create_access_token
from legendary.utils.queue import push_task

app = FastAPI(title="Legendary V11 Global SaaS")

@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    access_token = create_access_token({"sub": user["username"], "tenant": user["tenant"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/health")
def health():
    return {"status": "Legendary V11 running"}

@app.post("/task")
def create_task(task: str, tenant: str = "global"):
    push_task(task, tenant)
    return {"status": "task queued", "tenant": tenant}
EOF

echo "🚀 Creating Dockerfile..."
cat > Dockerfile <<EOF
FROM python:3.12-slim
WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir fastapi uvicorn redis python-jose passlib[bcrypt] pydantic[dotenv]
EXPOSE
