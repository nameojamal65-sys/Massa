#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd /data/data/com.termux/files/home

# Backup
if [ -f app/main.py ]; then
  cp -f app/main.py "app/main.py.bak.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p app

cat > app/main.py <<'PY'
from __future__ import annotations

from fastapi import FastAPI

from app.core.config import settings
from app.core.db import init_db
from app.core.middleware import add_middlewares
from app.api.v1.router import api_router

# UI router اختياري (ما نخليه يطيّح التطبيق لو غير موجود)
try:
    from app.web.router import router as ui_router  # type: ignore
except Exception:
    ui_router = None  # type: ignore


def create_app() -> FastAPI:
    app = FastAPI(title=settings.APP_NAME)

    add_middlewares(app)

    @app.on_event("startup")
    def _startup() -> None:
        init_db()

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok"}

    # API
    app.include_router(api_router, prefix="/api/v1")

    # UI (اختياري)
    if ui_router is not None:
        app.include_router(ui_router)

    return app


app = create_app()
PY

echo "✅ Wrote clean app/main.py"
python -m py_compile app/main.py
echo "✅ app/main.py compiles fine"
