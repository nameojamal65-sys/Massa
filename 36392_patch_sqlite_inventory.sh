#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="${1:-/data/data/com.termux/files/home/TremixProduct/apps/inventory_api_20260215_205130}"

if [ ! -d "$APP" ]; then
  echo "❌ APP dir not found: $APP"
  exit 1
fi

echo "🦅 Patching to SQLite: $APP"

# --- requirements (sqlite3 built-in; keep clean) ---
# (no change needed; but keep file consistent)
cat > "$APP/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

# --- app/db.py ---
mkdir -p "$APP/app"
cat > "$APP/app/db.py" <<'PY'
import os
import sqlite3
from contextlib import contextmanager
from typing import Iterator

def db_path() -> str:
    # Allow tests / env override
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

# --- app/main.py (SQLite CRUD) ---
cat > "$APP/app/main.py" <<'PY'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List
import time
import sqlite3

from app.db import get_conn

app = FastAPI(title="Inventory API", version="2.0.0-sqlite")

class ItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    sku: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=0, le=1_000_000)

class Item(ItemIn):
    id: int

def _now_ms() -> int:
    return int(time.time() * 1000)

@app.get("/health")
def health():
    with get_conn() as conn:
        n = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
    return {"ok": True, "items": int(n), "ts_ms": _now_ms()}

@app.get("/items", response_model=List[Item])
def list_items():
    with get_conn() as conn:
        rows = conn.execute("SELECT id, name, sku, quantity FROM items ORDER BY id").fetchall()
    return [dict(r) for r in rows]

@app.post("/items", response_model=Item, status_code=201)
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
            # UNIQUE(sku) or CHECK(quantity)
            raise HTTPException(status_code=409, detail="SKU already exists")
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    return dict(row)

@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int):
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, name, sku, quantity FROM items WHERE id=?",
            (item_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Item not found")
    return dict(row)

@app.put("/items/{item_id}", response_model=Item)
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

@app.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: int):
    with get_conn() as conn:
        cur = conn.execute("DELETE FROM items WHERE id=?", (item_id,))
        conn.commit()
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Item not found")
    return None
PY

# --- tests updated for SQLite (isolated DB file per run) ---
mkdir -p "$APP/tests"
cat > "$APP/tests/conftest.py" <<'PY'
import os, sys
import pytest
from pathlib import Path

# ensure project root import
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

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True
    assert r.json()["items"] == 0

def test_crud_flow_sqlite():
    # create
    r = client.post("/items", json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 201
    item = r.json()
    assert item["id"] == 1
    assert item["sku"] == "KB-001"

    # list
    r = client.get("/items")
    assert r.status_code == 200
    assert len(r.json()) == 1

    # get
    r = client.get("/items/1")
    assert r.status_code == 200
    assert r.json()["name"] == "Keyboard"

    # update
    r = client.put("/items/1", json={"name":"Keyboard Pro","sku":"KB-001","quantity":7})
    assert r.status_code == 200
    assert r.json()["quantity"] == 7

    # duplicate sku
    r = client.post("/items", json={"name":"Mouse","sku":"KB-001","quantity":1})
    assert r.status_code == 409

    # delete
    r = client.delete("/items/1")
    assert r.status_code == 204

    # gone
    r = client.get("/items/1")
    assert r.status_code == 404
PY

# --- pytest config to avoid PYTHONPATH issues ---
cat > "$APP/pytest.ini" <<'INI'
[pytest]
pythonpath = .
INI

echo "✅ Files patched. Running tests..."

cd "$APP"
. .venv/bin/activate
pip install -r requirements.txt >/dev/null
pytest -q

echo
echo "✅ SQLite patch complete."
echo "Run:"
echo "  cd \"$APP\" && . .venv/bin/activate && uvicorn app.main:app --host 127.0.0.1 --port 9000"
echo "DB file default: $APP/inventory.db (unless INVENTORY_DB is set)"
