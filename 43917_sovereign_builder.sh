#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="/data/data/com.termux/files/home/sovereign_core"
PYTHON=python3

echo "🚀 Building Sovereign Core..."

mkdir -p "$BASE"
cd "$BASE"

$PYTHON -m venv .venv
source .venv/bin/activate

pip install --upgrade pip >/dev/null
pip install fastapi uvicorn sqlalchemy pydantic jinja2 python-jose passlib[bcrypt] httpx openai >/dev/null

mkdir -p app/{core,api/v1,web/templates,ai}

touch app/__init__.py
touch app/core/__init__.py
touch app/api/__init__.py
touch app/api/v1/__init__.py
touch app/web/__init__.py
touch app/ai/__init__.py

# ================= CONFIG =================

cat > app/core/config.py <<'PY'
from pydantic import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Sovereign Core"
    SECRET_KEY: str = "CHANGE_ME_SECRET"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    OPENAI_API_KEY: str | None = None

settings = Settings()
PY

# ================= DB =================

cat > app/core/db.py <<'PY'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "sqlite:///./sovereign.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

def init_db():
    Base.metadata.create_all(bind=engine)
PY

# ================= AUTH =================

cat > app/core/auth.py <<'PY'
from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str):
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str):
    return pwd_context.verify(password, hashed)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
PY

# ================= MODELS =================

cat > app/core/models.py <<'PY'
from sqlalchemy import Column, Integer, String
from app.core.db import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(String, default="admin")
PY

# ================= API ROUTER =================

cat > app/api/v1/router.py <<'PY'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.db import SessionLocal
from app.core.models import User
from app.core.auth import hash_password, verify_password, create_access_token

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register")
def register(username: str, password: str, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == username).first():
        raise HTTPException(400, "User exists")
    user = User(username=username, password=hash_password(password))
    db.add(user)
    db.commit()
    return {"status": "created"}

@router.post("/login")
def login(username: str, password: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == username).first()
    if not user or not verify_password(password, user.password):
        raise HTTPException(401, "Invalid credentials")
    token = create_access_token({"sub": user.username})
    return {"access_token": token}
PY

# ================= AI AGENT =================

cat > app/ai/agent.py <<'PY'
import os
import shutil
from openai import OpenAI
from app.core.config import settings

client = OpenAI(api_key=settings.OPENAI_API_KEY)

PROJECT_ROOT = os.path.abspath(".")

def backup_file(path):
    shutil.copy(path, path + ".bak")

def modify_file(path: str, instruction: str):
    full_path = os.path.join(PROJECT_ROOT, path)
    if not os.path.exists(full_path):
        return {"error": "File not found"}

    with open(full_path, "r") as f:
        content = f.read()

    prompt = f"""
You are a senior Python engineer.
Modify the following file according to instruction.
Instruction:
{instruction}

File:
{content}
Return full modified file only.
"""

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role": "user", "content": prompt}]
    )

    new_code = response.choices[0].message.content

    backup_file(full_path)

    with open(full_path, "w") as f:
        f.write(new_code)

    return {"status": "modified"}
PY

# ================= AI ROUTE =================

cat > app/api/v1/ai.py <<'PY'
from fastapi import APIRouter
from app.ai.agent import modify_file

router = APIRouter()

@router.post("/ai/modify")
def ai_modify(path: str, instruction: str):
    return modify_file(path, instruction)
PY

# ================= WEB UI =================

cat > app/web/router.py <<'PY'
from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

@router.get("/ui", response_class=HTMLResponse)
def ui():
    return "<h1>Sovereign Core Running</h1>"
PY

# ================= MAIN =================

cat > app/main.py <<'PY'
from fastapi import FastAPI
from app.core.db import init_db
from app.api.v1.router import router as api_router
from app.api.v1.ai import router as ai_router
from app.web.router import router as ui_router

def create_app():
    app = FastAPI(title="Sovereign Core")

    @app.on_event("startup")
    def startup():
        init_db()

    app.include_router(api_router, prefix="/api/v1")
    app.include_router(ai_router, prefix="/api/v1")
    app.include_router(ui_router)

    return app

app = create_app()
PY

echo "✅ DONE."
echo "Run:"
echo "cd sovereign_core"
echo "source .venv/bin/activate"
echo "uvicorn app.main:app --reload"
