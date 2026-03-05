#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="${1:-/data/data/com.termux/files/home/TremixProduct/apps/inventory_api_20260215_205130}"

if [ ! -d "$APP" ]; then
  echo "❌ APP dir not found: $APP"
  exit 1
fi

echo "🦅 Upgrade v3 -> $APP"

mkdir -p "$APP/app" "$APP/tests" "$APP/scripts"

# ---------------- deps ----------------
cat > "$APP/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

# optional dev deps (CI local)
cat > "$APP/requirements-dev.txt" <<'EOF'
ruff
EOF

# ---------------- db layer ----------------
cat > "$APP/app/db.py" <<'PY'
import os
import sqlite3
from contextlib import contextmanager
from typing import Iterator

def db_path() -> str:
    return os.environ.get("INVENTORY_DB", os.path.abspath("inventory.db"))

def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(db_path(), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db(conn: sqlite3.Connection) -> None:
    conn.execute("""
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sku TEXT NOT NULL UNIQUE,
      quantity INTEGER NOT NULL CHECK(quantity >= 0)
    );
    """)
    # helpful index for search
    conn.execute("CREATE INDEX IF NOT EXISTS idx_items_name ON items(name);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_items_sku ON items(sku);")
    conn.commit()

@contextmanager
def get_conn() -> Iterator[sqlite3.Connection]:
    conn = connect()
    try:
        init_db(conn)
        yield conn
    finally:
        conn.close()
PY

# ---------------- API (v3: pagination + search + openapi examples) ----------------
cat > "$APP/app/main.py" <<'PY'
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
import time
import sqlite3

from app.db import get_conn

app = FastAPI(
    title="Inventory API",
    version="3.0.0",
    description="SQLite-backed Inventory API with pagination + search + tests",
)

class ItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=120, examples=["Keyboard"])
    sku: str = Field(min_length=1, max_length=64, examples=["KB-001"])
    quantity: int = Field(ge=0, le=1_000_000, examples=[5])

class Item(ItemIn):
    id: int

def _now_ms() -> int:
    return int(time.time() * 1000)

@app.get("/health", tags=["system"])
def health():
    with get_conn() as conn:
        n = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
    return {"ok": True, "items": int(n), "ts_ms": _now_ms(), "version": app.version}

@app.get(
    "/items",
    response_model=List[Item],
    tags=["items"],
    summary="List items",
    description="List items with optional search and pagination.",
)
def list_items(
    q: Optional[str] = Query(default=None, description="Search in name or sku (contains)"),
    limit: int = Query(default=50, ge=1, le=200, description="Page size"),
    offset: int = Query(default=0, ge=0, description="Offset for pagination"),
    sort: str = Query(default="id", pattern="^(id|name|sku|quantity)$", description="Sort column"),
    order: str = Query(default="asc", pattern="^(asc|desc)$", description="Sort order"),
):
    where = ""
    params = []
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

@app.post(
    "/items",
    response_model=Item,
    status_code=201,
    tags=["items"],
    summary="Create item",
)
def create_item(payload: ItemIn):
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

@app.get(
    "/items/{item_id}",
    response_model=Item,
    tags=["items"],
    summary="Get item",
)
def get_item(item_id: int):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Item not found")
    return dict(row)

@app.put(
    "/items/{item_id}",
    response_model=Item,
    tags=["items"],
    summary="Update item",
)
def update_item(item_id: int, payload: ItemIn):
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

@app.delete(
    "/items/{item_id}",
    status_code=204,
    tags=["items"],
    summary="Delete item",
)
def delete_item(item_id: int):
    with get_conn() as conn:
        cur = conn.execute("DELETE FROM items WHERE id=?", (item_id,))
        conn.commit()
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Item not found")
    return None
PY

# ---------------- tests (v3 adds search/pagination/sort) ----------------
cat > "$APP/tests/conftest.py" <<'PY'
import os, sys
import pytest
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

@pytest.fixture(autouse=True)
def temp_db(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    db = tmp_path / "test_inventory.db"
    monkeypatch.setenv("INVENTORY_DB", str(db))
    yield
PY

cat > "$APP/tests/test_inventory.py" <<'PY'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def seed():
    client.post("/items", json={"name":"Keyboard","sku":"KB-001","quantity":5})
    client.post("/items", json={"name":"Mouse","sku":"MS-001","quantity":3})
    client.post("/items", json={"name":"Monitor","sku":"MN-001","quantity":2})

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True
    assert "version" in r.json()

def test_crud_and_search_pagination():
    seed()

    # list default
    r = client.get("/items")
    assert r.status_code == 200
    assert len(r.json()) == 3

    # search by sku
    r = client.get("/items", params={"q": "KB-"})
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert r.json()[0]["sku"] == "KB-001"

    # pagination
    r = client.get("/items", params={"limit": 2, "offset": 0, "sort": "name", "order": "asc"})
    assert r.status_code == 200
    assert len(r.json()) == 2

    # create conflict
    r = client.post("/items", json={"name":"X","sku":"KB-001","quantity":1})
    assert r.status_code == 409

    # get/update/delete
    r = client.get("/items/1")
    assert r.status_code == 200

    r = client.put("/items/1", json={"name":"Keyboard Pro","sku":"KB-001","quantity":7})
    assert r.status_code == 200
    assert r.json()["quantity"] == 7

    r = client.delete("/items/1")
    assert r.status_code == 204
    r = client.get("/items/1")
    assert r.status_code == 404
PY

# ---------------- configs ----------------
cat > "$APP/pytest.ini" <<'INI'
[pytest]
pythonpath = .
INI

cat > "$APP/ruff.toml" <<'TOML'
line-length = 100
target-version = "py310"
extend-select = ["I"]
exclude = [".venv","venv","__pycache__",".pytest_cache"]
TOML

# ---------------- Makefile (CI local) ----------------
cat > "$APP/Makefile" <<'MK'
SHELL := /bin/bash

.PHONY: venv install dev test lint run

venv:
python3 -m venv .venv

install: venv
. .venv/bin/activate && pip install -U pip && pip install -r requirements.txt

dev: install
. .venv/bin/activate && pip install -r requirements-dev.txt

test:
. .venv/bin/activate && pytest -q

lint:
. .venv/bin/activate && ruff check .

run:
. .venv/bin/activate && uvicorn app.main:app --host 127.0.0.1 --port 9000
MK

# ---------------- Dockerfile (optional, for non-Termux environments) ----------------
cat > "$APP/Dockerfile" <<'DOCK'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
EXPOSE 9000
ENV INVENTORY_DB=/app/inventory.db
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9000"]
DOCK

# ---------------- run scripts ----------------
cat > "$APP/scripts/run_bg.sh" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-9000}"
LOG="run.log"
. .venv/bin/activate
nohup uvicorn app.main:app --host 127.0.0.1 --port "$PORT" > "$LOG" 2>&1 & disown
echo "✅ running http://127.0.0.1:$PORT"
echo "🧾 $LOG"
BASH
chmod +x "$APP/scripts/run_bg.sh"

# ---------------- apply + verify ----------------
echo "✅ Files written. Installing + testing + lint..."

cd "$APP"
. .venv/bin/activate 2>/dev/null || true

python3 -m venv .venv >/dev/null 2>&1 || true
. .venv/bin/activate
pip install -U pip >/dev/null
pip install -r requirements.txt >/dev/null
pip install -r requirements-dev.txt >/dev/null

pytest -q
ruff check .

echo
echo "🎉 v3 upgrade complete."
echo "Run:"
echo "  cd \"$APP\" && make dev && make test && make lint"
echo "  cd \"$APP\" && make run"
echo "Docs:"
echo "  http://127.0.0.1:9000/docs"
echo "Search example:"
echo "  curl -s 'http://127.0.0.1:9000/items?q=KB&limit=10&offset=0&sort=id&order=asc'"
