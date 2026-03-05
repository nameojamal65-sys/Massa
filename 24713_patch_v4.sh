#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="${1:-/data/data/com.termux/files/home/TremixProduct/apps/inventory_api_20260215_205130}"
if [ ! -d "$APP" ]; then
  echo "❌ APP dir not found: $APP"
  exit 1
fi

echo "🦅 Upgrade v4 -> $APP"
mkdir -p "$APP/app" "$APP/tests" "$APP/scripts"

# ---------------- deps ----------------
cat > "$APP/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

cat > "$APP/requirements-dev.txt" <<'EOF'
ruff
EOF

# ---------------- config ----------------
cat > "$APP/app/config.py" <<'PY'
import os

def api_key() -> str:
    # You MUST set this in production:
    # export INVENTORY_API_KEY="change-me"
    return os.environ.get("INVENTORY_API_KEY", "dev-key-change-me")

def db_path() -> str:
    return os.environ.get("INVENTORY_DB", os.path.abspath("inventory.db"))

def rate_limit_per_minute() -> int:
    # per API key
    return int(os.environ.get("INVENTORY_RL_PER_MIN", "120"))
PY

# ---------------- logging ----------------
cat > "$APP/app/logging_utils.py" <<'PY'
import json, time, os
from typing import Any, Dict

LOG_FILE = os.environ.get("INVENTORY_LOG", os.path.abspath("inventory.log"))

def log(event: str, **fields: Any) -> None:
    rec: Dict[str, Any] = {
        "ts": int(time.time()),
        "event": event,
        **fields,
    }
    line = json.dumps(rec, ensure_ascii=False)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")
PY

# ---------------- db ----------------
cat > "$APP/app/db.py" <<'PY'
import sqlite3
from contextlib import contextmanager
from typing import Iterator
from app.config import db_path

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

# ---------------- auth + rate limit ----------------
cat > "$APP/app/security.py" <<'PY'
import time
from typing import Dict, Tuple
from fastapi import HTTPException, Request
from app.config import api_key, rate_limit_per_minute
from app.logging_utils import log

# token bucket per key in-memory (OK for single-node)
_BUCKETS: Dict[str, Tuple[float, float]] = {}  # key -> (tokens, last_ts)

def require_api_key(request: Request) -> str:
    k = request.headers.get("x-api-key", "")
    if not k or k != api_key():
        log("auth_failed", ip=getattr(request.client, "host", ""), path=str(request.url.path))
        raise HTTPException(status_code=401, detail="unauthorized")
    return k

def rate_limit(key: str):
    cap = float(rate_limit_per_minute())
    refill_per_sec = cap / 60.0
    now = time.time()
    tokens, last = _BUCKETS.get(key, (cap, now))
    # refill
    tokens = min(cap, tokens + (now - last) * refill_per_sec)
    if tokens < 1.0:
        raise HTTPException(status_code=429, detail="rate_limited")
    tokens -= 1.0
    _BUCKETS[key] = (tokens, now)
PY

# ---------------- main API (v4) ----------------
cat > "$APP/app/main.py" <<'PY'
from fastapi import FastAPI, HTTPException, Query, Request
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import time
import sqlite3
import json

from app.db import get_conn
from app.security import require_api_key, rate_limit
from app.logging_utils import log

app = FastAPI(
    title="Inventory API",
    version="4.0.0",
    description="Versioned API (/api/v1) + API key + rate limit + logging + import/export",
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

@app.get("/health", tags=["system"])
def health():
    with get_conn() as conn:
        n = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
    return {"ok": True, "items": int(n), "ts_ms": _now_ms(), "version": app.version}

# ---------------- Versioned API ----------------

@app.get("/api/v1/items", response_model=List[Item], tags=["items"])
def list_items(
    request: Request,
    q: Optional[str] = Query(default=None, description="Search in name or sku (contains)"),
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

@app.post("/api/v1/items", response_model=Item, status_code=201, tags=["items"])
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

@app.get("/api/v1/items/{item_id}", response_model=Item, tags=["items"])
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

@app.put("/api/v1/items/{item_id}", response_model=Item, tags=["items"])
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

@app.delete("/api/v1/items/{item_id}", status_code=204, tags=["items"])
def delete_item(request: Request, item_id: int):
    _guard(request)
    with get_conn() as conn:
        cur = conn.execute("DELETE FROM items WHERE id=?", (item_id,))
        conn.commit()
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Item not found")
    return None

# ---------------- import/export + seed ----------------

@app.get("/api/v1/export", tags=["ops"])
def export_items(request: Request):
    _guard(request)
    with get_conn() as conn:
        rows = conn.execute("SELECT id, name, sku, quantity FROM items ORDER BY id").fetchall()
    return {"items": [dict(r) for r in rows]}

@app.post("/api/v1/import", tags=["ops"])
def import_items(request: Request, payload: Dict[str, Any]):
    _guard(request)
    items = payload.get("items", [])
    if not isinstance(items, list):
        raise HTTPException(status_code=400, detail="items must be a list")
    inserted = 0
    skipped = 0
    with get_conn() as conn:
        for it in items:
            try:
                conn.execute(
                    "INSERT INTO items(name, sku, quantity) VALUES(?,?,?)",
                    (it["name"], it["sku"], int(it["quantity"])),
                )
                inserted += 1
            except Exception:
                skipped += 1
        conn.commit()
    return {"ok": True, "inserted": inserted, "skipped": skipped}

@app.post("/api/v1/seed", tags=["ops"])
def seed(request: Request):
    _guard(request)
    base = [
        {"name":"Keyboard","sku":"KB-001","quantity":5},
        {"name":"Mouse","sku":"MS-001","quantity":3},
        {"name":"Monitor","sku":"MN-001","quantity":2},
    ]
    return import_items(request, {"items": base})
PY

# ---------------- tests (auth + rl + v1 routes) ----------------
cat > "$APP/tests/conftest.py" <<'PY'
import os, sys
import pytest
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

@pytest.fixture(autouse=True)
def env(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    db = tmp_path / "test_inventory.db"
    monkeypatch.setenv("INVENTORY_DB", str(db))
    monkeypatch.setenv("INVENTORY_API_KEY", "test-key")
    monkeypatch.setenv("INVENTORY_RL_PER_MIN", "9999")  # avoid flakiness
    yield
PY

cat > "$APP/tests/test_v4.py" <<'PY'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
H = {"x-api-key": "test-key"}

def test_health_open():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True

def test_auth_required():
    r = client.get("/api/v1/items")
    assert r.status_code == 401

def test_crud_v1():
    r = client.post("/api/v1/items", headers=H, json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 201
    r = client.get("/api/v1/items", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/api/v1/items?q=KB", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/api/v1/export", headers=H)
    assert r.status_code == 200
    assert "items" in r.json()

    r = client.post("/api/v1/seed", headers=H)
    assert r.status_code == 200
    assert r.json()["ok"] is True
PY

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

# ---------------- Makefile ----------------
cat > "$APP/Makefile" <<'MK'
SHELL := /bin/bash

.PHONY: venv install dev test lint run run-bg

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
. .venv/bin/activate && INVENTORY_API_KEY=$${INVENTORY_API_KEY:-dev-key-change-me} uvicorn app.main:app --host 127.0.0.1 --port 9000

run-bg:
bash scripts/run_bg.sh
MK

# ---------------- run script ----------------
cat > "$APP/scripts/run_bg.sh" <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
PORT="${PORT:-9000}"
LOG="run.log"
: "${INVENTORY_API_KEY:=dev-key-change-me}"
. .venv/bin/activate
nohup env INVENTORY_API_KEY="$INVENTORY_API_KEY" uvicorn app.main:app --host 127.0.0.1 --port "$PORT" > "$LOG" 2>&1 & disown
echo "✅ running http://127.0.0.1:$PORT"
echo "🔑 x-api-key: $INVENTORY_API_KEY"
echo "🧾 $LOG"
BASH
chmod +x "$APP/scripts/run_bg.sh"

# ---------------- verify ----------------
echo "✅ Installing + testing + lint..."
cd "$APP"
python3 -m venv .venv >/dev/null 2>&1 || true
. .venv/bin/activate
pip install -U pip >/dev/null
pip install -r requirements.txt >/dev/null
pip install -r requirements-dev.txt >/dev/null

pytest -q
ruff check .

echo
echo "🎉 v4 complete."
echo "Run:"
echo "  cd \"$APP\""
echo "  export INVENTORY_API_KEY='change-me-now'"
echo "  make dev && make test && make lint"
echo "  make run"
echo
echo "Examples:"
echo "  curl -s http://127.0.0.1:9000/health ; echo"
echo "  curl -s -H 'x-api-key: change-me-now' http://127.0.0.1:9000/api/v1/items ; echo"
echo "  curl -s -X POST -H 'x-api-key: change-me-now' -H 'content-type: application/json' \\"
echo "    http://127.0.0.1:9000/api/v1/items -d '{\"name\":\"Mouse\",\"sku\":\"MS-001\",\"quantity\":3}' ; echo"
echo "Docs:"
echo "  http://127.0.0.1:9000/docs"
