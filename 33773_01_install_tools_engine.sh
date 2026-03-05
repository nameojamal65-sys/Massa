#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd /data/data/com.termux/files/home

# shellcheck disable=SC1091
source .venv/bin/activate

echo "==[ STAGE 1: INSTALL TOOLS ENGINE ]========"

mkdir -p app/tools app/api/v1

cat > app/tools/registry.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable, Dict, Optional


@dataclass(frozen=True)
class Tool:
    name: str
    description: str
    handler: Callable[[Dict[str, Any]], Dict[str, Any]]
    input_schema: Dict[str, Any]


_REGISTRY: Dict[str, Tool] = {}


def register(tool: Tool) -> None:
    if tool.name in _REGISTRY:
        raise ValueError(f"Tool already registered: {tool.name}")
    _REGISTRY[tool.name] = tool


def list_tools() -> Dict[str, Dict[str, Any]]:
    return {
        name: {
            "name": t.name,
            "description": t.description,
            "input_schema": t.input_schema,
        }
        for name, t in sorted(_REGISTRY.items())
    }


def get_tool(name: str) -> Optional[Tool]:
    return _REGISTRY.get(name)
PY

cat > app/tools/builtin.py <<'PY'
from __future__ import annotations

from typing import Any, Dict

from app.tools.registry import Tool, register
from app.core.db import SessionLocal

# NOTE:
# هذا يفترض مشروعك عنده app/db/models.py وفيه الكلاسات التالية:
# User, Task, FileAsset, ApiKey, Tenant
from app.db import models


def _tool_health_ping(payload: Dict[str, Any]) -> Dict[str, Any]:
    return {"ok": True, "echo": payload}


register(
    Tool(
        name="health_ping",
        description="Sanity tool: returns ok + echoes payload.",
        handler=_tool_health_ping,
        input_schema={
            "type": "object",
            "properties": {"msg": {"type": "string"}},
            "required": [],
        },
    )
)


def _tool_db_stats(payload: Dict[str, Any]) -> Dict[str, Any]:
    db = SessionLocal()
    try:
        return {
            "tables": {
                "users": db.query(models.User).count(),
                "tasks": db.query(models.Task).count(),
                "file_assets": db.query(models.FileAsset).count(),
                "api_keys": db.query(models.ApiKey).count(),
                "tenants": db.query(models.Tenant).count(),
            }
        }
    finally:
        db.close()


register(
    Tool(
        name="db_stats",
        description="Counts core entities in DB.",
        handler=_tool_db_stats,
        input_schema={"type": "object", "properties": {}, "required": []},
    )
)
PY

cat > app/api/v1/tools.py <<'PY'
from __future__ import annotations

from typing import Any, Dict

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

# ensure builtin tools are registered on import
from app.tools import builtin  # noqa: F401
from app.tools.registry import list_tools, get_tool

router = APIRouter(tags=["tools"])


class ToolRunIn(BaseModel):
    name: str = Field(..., description="Tool name")
    input: Dict[str, Any] = Field(default_factory=dict, description="Tool payload")


@router.get("/tools")
def tools_list() -> Dict[str, Any]:
    return {"tools": list_tools()}


@router.post("/tools/run")
def tools_run(body: ToolRunIn) -> Dict[str, Any]:
    tool = get_tool(body.name)
    if not tool:
        raise HTTPException(status_code=404, detail=f"Unknown tool: {body.name}")
    try:
        out = tool.handler(body.input or {})
        return {"name": tool.name, "output": out}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"{type(e).__name__}: {e}")
PY

touch app/tools/__init__.py

echo "✅ Patching app/api/v1/router.py to include tools router..."

ROUTER="app/api/v1/router.py"

if ! grep -q "from app.api.v1.tools import router as tools_router" "$ROUTER"; then
  printf '\nfrom app.api.v1.tools import router as tools_router\n' >> "$ROUTER"
fi

if ! grep -q "include_router(tools_router" "$ROUTER"; then
  printf '\nrouter.include_router(tools_router)\n' >> "$ROUTER"
fi

echo "✅ Compile check..."
python -m py_compile app/tools/registry.py
python -m py_compile app/tools/builtin.py
python -m py_compile app/api/v1/tools.py
python -m py_compile app/api/v1/router.py

echo
echo "🎉 STAGE 1 DONE."
echo "Endpoints:"
echo "  GET  /api/v1/tools"
echo "  POST /api/v1/tools/run"
echo "=========================================="
