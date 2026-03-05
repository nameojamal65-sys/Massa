from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

@router.get("/ui", response_class=HTMLResponse)
def ui():
    return "<h1>Sovereign Core Running</h1>"
