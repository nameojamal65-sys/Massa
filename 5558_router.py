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
