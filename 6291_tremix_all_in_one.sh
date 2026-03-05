#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="$HOME/TremixProduct"
APP_DIR="${APP_DIR:-$BASE/apps/inventory_v4}"
PORT="${PORT:-9000}"
API_KEY="${INVENTORY_API_KEY:-change-me-now}"
DB_PATH="${INVENTORY_DB:-$APP_DIR/inventory.db}"
LOG_PATH="${INVENTORY_LOG:-$APP_DIR/inventory.log}"
RL_PER_MIN="${INVENTORY_RL_PER_MIN:-120}"

say(){ echo -e "🦅 $*"; }

say "Installing essentials..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y python curl >/dev/null 2>&1 || true
python3 -m ensurepip --upgrade >/dev/null 2>&1 || true
python3 -m pip install -U pip setuptools wheel >/dev/null 2>&1 || true

say "Creating product at: $APP_DIR"
mkdir -p "$APP_DIR/app" "$APP_DIR/tests" "$APP_DIR/scripts"

cat > "$APP_DIR/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

cat > "$APP_DIR/requirements-dev.txt" <<'EOF'
ruff
EOF

cat > "$APP_DIR/app/__init__.py" <<'EOF'
EOF

cat > "$APP_DIR/app/config.py" <<'PY'
import os
def api_key() -> str: return os.environ.get("INVENTORY_API_KEY", "dev-key-change-me")
def db_path() -> str: return os.environ.get("INVENTORY_DB", os.path.abspath("inventory.db"))
def rate_limit_per_minute() -> int: return int(os.environ.get("INVENTORY_RL_PER_MIN", "120"))
def log_path() -> str: return os.environ.get("INVENTORY_LOG", os.path.abspath("inventory.log"))
PY

cat > "$APP_DIR/app/logging_utils.py" <<'PY'
import json, time
from typing import Any, Dict
from app.config import log_path
def log(event: str, **fields: Any) -> None:
    rec: Dict[str, Any] = {"ts": int(time.time()), "event": event, **fields}
    with open(log_path(), "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
PY

cat > "$APP_DIR/app/db.py" <<'PY'
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

cat > "$APP_DIR/app/security.py" <<'PY'
import time
from typing import Dict, Tuple
from fastapi import HTTPException, Request
from app.config import api_key, rate_limit_per_minute
from app.logging_utils import log

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
    tokens = min(cap, tokens + (now - last) * refill_per_sec)
    if tokens < 1.0:
        raise HTTPException(status_code=429, detail="rate_limited")
    tokens -= 1.0
    _BUCKETS[key] = (tokens, now)
PY

cat > "$APP_DIR/app/main.py" <<'PY'
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
    name: str = Field(min_length=1, max_length=120)
    sku: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=0, le=1_000_000)

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
PY

cat > "$APP_DIR/tests/conftest.py" <<'PY'
import os, sys
import pytest
from pathlib import Path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

@pytest.fixture(autouse=True)
def env(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("INVENTORY_DB", str(tmp_path / "test.db"))
    monkeypatch.setenv("INVENTORY_API_KEY", "test-key")
    monkeypatch.setenv("INVENTORY_RL_PER_MIN", "9999")
    monkeypatch.setenv("INVENTORY_LOG", str(tmp_path / "test.log"))
    yield
PY

cat > "$APP_DIR/tests/test_app.py" <<'PY'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)
H={"x-api-key":"test-key"}

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True

def test_auth_required():
    r = client.get("/api/v1/items")
    assert r.status_code == 401

def test_crud():
    r = client.post("/api/v1/items", headers=H, json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 201
    r = client.get("/api/v1/items", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1
PY

cat > "$APP_DIR/ruff.toml" <<'TOML'
line-length = 100
target-version = "py310"
extend-select = ["I"]
exclude = [".venv","venv","__pycache__",".pytest_cache"]
TOML

cat > "$APP_DIR/scripts/run_bg.sh" <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
PORT="${PORT:-9000}"
: "${INVENTORY_API_KEY:=change-me-now}"
: "${INVENTORY_DB:=inventory.db}"
: "${INVENTORY_LOG:=inventory.log}"
: "${INVENTORY_RL_PER_MIN:=120}"

. .venv/bin/activate
nohup env INVENTORY_API_KEY="$INVENTORY_API_KEY" INVENTORY_DB="$INVENTORY_DB" INVENTORY_LOG="$INVENTORY_LOG" INVENTORY_RL_PER_MIN="$INVENTORY_RL_PER_MIN" \
  uvicorn app.main:app --host 127.0.0.1 --port "$PORT" > run.log 2>&1 & disown
echo "✅ running http://127.0.0.1:$PORT"
echo "🔑 x-api-key: $INVENTORY_API_KEY"
echo "🗄️  db: $INVENTORY_DB"
echo "🧾 run.log: $(pwd)/run.log"
BASH
chmod +x "$APP_DIR/scripts/run_bg.sh"

say "Creating venv + installing deps..."
cd "$APP_DIR"
python3 -m venv .venv >/dev/null 2>&1 || true
. .venv/bin/activate
pip install -U pip >/dev/null
pip install -r requirements.txt >/dev/null
pip install -r requirements-dev.txt >/dev/null

say "Running tests..."
pytest -q

say "Linting (ruff)..."
ruff check . >/dev/null

say "Starting server in background..."
export INVENTORY_API_KEY="$API_KEY"
export INVENTORY_DB="$DB_PATH"
export INVENTORY_LOG="$LOG_PATH"
export INVENTORY_RL_PER_MIN="$RL_PER_MIN"

# auto-bump port if busy
python3 - <<PY >/dev/null 2>&1 || PORT=$((PORT+1))
import socket
s=socket.socket(); s.settimeout(0.2)
s.connect(("127.0.0.1", int("$PORT")))
PY

bash scripts/run_bg.sh

say "Smoke test..."
curl -s "http://127.0.0.1:$PORT/health" ; echo

say "DONE ✅"
echo "📁 App: $APP_DIR"
echo "🌐 Docs: http://127.0.0.1:$PORT/docs"
echo "🔌 API:  http://127.0.0.1:$PORT/api/v1"
echo "🔑 Header: x-api-key: $API_KEY"
echo
echo "Try:"
echo "  curl -s -H 'x-api-key: $API_KEY' http://127.0.0.1:$PORT/api/v1/items ; echo"
echo "  curl -s -X POST -H 'x-api-key: $API_KEY' -H 'content-type: application/json' \\"
echo "    http://127.0.0.1:$PORT/api/v1/items -d '{\"name\":\"Mouse\",\"sku\":\"MS-001\",\"quantity\":3}' ; echo"
