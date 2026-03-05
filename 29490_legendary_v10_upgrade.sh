#!/bin/bash

echo "🚀 Upgrading to Legendary V10 Distributed SaaS..."

BASE_DIR=~/Legendary_Dashboard
cd $BASE_DIR || exit

echo "📦 Installing dependencies..."
pkg install redis -y
pip install redis python-jose passlib[bcrypt] fastapi uvicorn --break-system-packages 2>/dev/null

echo "🧠 Creating config..."
cat > legendary/config.py <<EOF
SECRET_KEY = "legendary_super_secret_key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REDIS_HOST = "localhost"
REDIS_PORT = 6379
EOF

echo "🔐 Creating Auth System..."
cat > legendary/api/auth.py <<EOF
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from legendary.config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

fake_users_db = {
    "admin": {
        "username": "admin",
        "hashed_password": pwd_context.hash("admin123")
    }
}

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def authenticate_user(username, password):
    user = fake_users_db.get(username)
    if not user:
        return False
    if not verify_password(password, user["hashed_password"]):
        return False
    return user

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
EOF

echo "📨 Creating Redis Queue..."
cat > legendary/utils/queue.py <<EOF
import redis
from legendary.config import REDIS_HOST, REDIS_PORT

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT)

def push_task(task):
    r.lpush("legendary_queue", task)

def pop_task():
    return r.rpop("legendary_queue")
EOF

echo "⚙️ Creating Worker..."
cat > legendary/worker.py <<EOF
import time
from legendary.utils.queue import pop_task

print("🛰 Legendary Worker started...")

while True:
    task = pop_task()
    if task:
        print(f"🔥 Processing task: {task.decode()}")
    time.sleep(2)
EOF

echo "🌐 Upgrading API Server..."
cat > legendary/api/server.py <<EOF
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from legendary.api.auth import authenticate_user, create_access_token
from legendary.utils.queue import push_task

app = FastAPI(title="Legendary Global SaaS V10")

@app.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    access_token = create_access_token({"sub": user["username"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/health")
def health():
    return {"status": "Legendary V10 running"}

@app.post("/task")
def create_task(task: str):
    push_task(task)
    return {"status": "task queued"}
EOF

echo "🚀 Updating app entry..."
cat > app.py <<EOF
import uvicorn

if __name__ == "__main__":
    uvicorn.run("legendary.api.server:app", host="0.0.0.0", port=8000)
EOF

echo "🛰 Creating worker runner..."
cat > run_worker.sh <<EOF
#!/bin/bash
python3 -m legendary.worker
EOF

chmod +x run_worker.sh

echo "🏁 V10 Ready!"
echo ""
echo "1️⃣ Start Redis:"
echo "redis-server &"
echo ""
echo "2️⃣ Start API:"
echo "python3 app.py"
echo ""
echo "3️⃣ Start Worker:"
echo "./run_worker.sh"
echo ""
echo "Swagger:"
echo "http://localhost:8000/docs"
