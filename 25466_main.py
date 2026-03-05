from fastapi import FastAPI, HTTPException, Query, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Any
import time
import sqlite3

from app.db import get_conn
from app.security import require_api_key, rate_limit
from app.logging_utils import log

app = FastAPI(
    title="Inventory API",
    version="4.0.0",
    description="Versioned API (/api/v1) + API key + rate limit + logging",
)

class ItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=120, examples=["Keyboard"])
    sku: str = Field(min_length=1, max_length=64, examples=["KB-001"])
    quantity: int = Field(ge=0, le=1_000_000, examples=[5])

class Item(ItemIn):
    id: int

def _now_ms() -> int:
    return int(time.time() * 1000)

def _guard(request: Request) -> str:
    key = require_api_key(request)
    rate_limit(key)
    return key

@app.middleware("http")
async def audit_middleware(request: Request, call_next):
    t0 = time.time()
    try:
        resp = await call_next(request)
        dt = int((time.time() - t0) * 1000)
        log("http", method=request.method, path=str(request.url.path), status=resp.status_code, ms=dt)
        return resp
    except Exception as e:
        dt = int((time.time() - t0) * 1000)
        log("http_error", method=request.method, path=str(request.url.path), ms=dt, err=str(e))
        raise

@app.get("/health")
def health():
    with get_conn() as conn:
        n = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
    return {"ok": True, "items": int(n), "ts_ms": _now_ms(), "version": app.version}

@app.get("/api/v1/items", response_model=List[Item])
def list_items(
    request: Request,
    q: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    sort: str = Query(default="id", pattern="^(id|name|sku|quantity)$"),
    order: str = Query(default="asc", pattern="^(asc|desc)$"),
):
    _guard(request)
    where = ""
    params: List[Any] = []
    if q:
        where = "WHERE name LIKE ? OR sku LIKE ?"
        like = f"%{q}%"
        params += [like, like]
    sql = f"""
    SELECT id, name, sku, quantity
    FROM items
    {where}
    ORDER BY {sort} {order}
    LIMIT ? OFFSET ?
    """
    params += [limit, offset]
    with get_conn() as conn:
        rows = conn.execute(sql, params).fetchall()
    return [dict(r) for r in rows]

@app.post("/api/v1/items", response_model=Item, status_code=201)
def create_item(request: Request, payload: ItemIn):
    _guard(request)
    with get_conn() as conn:
        try:
            cur = conn.execute(
                "INSERT INTO items(name, sku, quantity) VALUES(?,?,?)",
                (payload.name, payload.sku, payload.quantity),
            )
            conn.commit()
            item_id = cur.lastrowid
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=409, detail="SKU already exists")
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    return dict(row)

@app.get("/api/v1/items/{item_id}", response_model=Item)
def get_item(request: Request, item_id: int):
    _guard(request)
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Item not found")
    return dict(row)

@app.put("/api/v1/items/{item_id}", response_model=Item)
def update_item(request: Request, item_id: int, payload: ItemIn):
    _guard(request)
    with get_conn() as conn:
        exists = conn.execute("SELECT 1 FROM items WHERE id=?", (item_id,)).fetchone()
        if not exists:
            raise HTTPException(status_code=404, detail="Item not found")
        try:
            conn.execute(
                "UPDATE items SET name=?, sku=?, quantity=? WHERE id=?",
                (payload.name, payload.sku, payload.quantity, item_id),
            )
            conn.commit()
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=409, detail="SKU already exists")
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    return dict(row)

@app.delete("/api/v1/items/{item_id}", status_code=204)
def delete_item(request: Request, item_id: int):
    _guard(request)
    with get_conn() as conn:
        cur = conn.execute("DELETE FROM items WHERE id=?", (item_id,))
        conn.commit()
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Item not found")
    return None
