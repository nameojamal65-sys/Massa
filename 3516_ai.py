from fastapi import APIRouter
from app.ai.agent import modify_file

router = APIRouter()

@router.post("/ai/modify")
def ai_modify(path: str, instruction: str):
    return modify_file(path, instruction)
