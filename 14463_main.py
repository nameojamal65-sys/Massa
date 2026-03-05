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
