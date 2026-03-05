#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="${1:-/data/data/com.termux/files/home/TremixProduct/apps/inventory_api_20260215_205130}"

if [ ! -d "$APP" ]; then
  echo "❌ APP dir not found: $APP"
  exit 1
fi

echo "🦅 Installing v5 Enterprise Upgrade..."

mkdir -p "$APP/app" "$APP/tests"

# ---------------- requirements ----------------
cat > "$APP/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

# ---------------- config ----------------
cat > "$APP/app/config.py" <<'PY'
import os

API_KEY = os.environ.get("INVENTORY_API_KEY", "dev-admin-key")
DB_PATH = os.environ.get("INVENTORY_DB", "inventory.db")
RL_PER_MIN = int(os.environ.get("INVENTORY_RL_PER_MIN", "120"))
PY

# ---------------- db (with rate limit table) ----------------
cat > "$APP/app/db.py" <<'PY'
import sqlite3, time
from contextlib import contextmanager
from app.config import DB_PATH

def connect():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db(conn):
    conn.execute("""
    CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT UNIQUE NOT NULL,
        quantity INTEGER NOT NULL
    );
    """)
    conn.execute("""
    CREATE TABLE IF NOT EXISTS rate_limit (
        api_key TEXT PRIMARY KEY,
        tokens REAL,
        last_ts REAL
    );
    """)
    conn.commit()

@contextmanager
def get_conn():
    conn = connect()
    init_db(conn)
    try:
        yield conn
    finally:
        conn.close()
PY

# ---------------- security ----------------
cat > "$APP/app/security.py" <<'PY'
import time
from fastapi import HTTPException, Request
from app.config import API_KEY, RL_PER_MIN
from app.db import get_conn

def require_key(request: Request):
    key = request.headers.get("x-api-key")
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="unauthorized")
    return key

def rate_limit(key: str):
    with get_conn() as conn:
        row = conn.execute("SELECT tokens, last_ts FROM rate_limit WHERE api_key=?", (key,)).fetchone()
        now = time.time()
        capacity = RL_PER_MIN
        refill = capacity / 60

        if not row:
            tokens = capacity - 1
            conn.execute("INSERT INTO rate_limit VALUES (?,?,?)", (key, tokens, now))
        else:
            tokens, last = row
            tokens = min(capacity, tokens + (now - last) * refill)
            if tokens < 1:
                raise HTTPException(status_code=429, detail="rate_limited")
            tokens -= 1
            conn.execute("UPDATE rate_limit SET tokens=?, last_ts=? WHERE api_key=?", (tokens, now, key))
        conn.commit()
PY

# ---------------- main ----------------
cat > "$APP/app/main.py" <<'PY'
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import uuid, csv, io
from typing import List
from app.db import get_conn
from app.security import require_key, rate_limit

app = FastAPI(title="Inventory Enterprise", version="5.0.0")

class Item(BaseModel):
    name: str
    sku: str
    quantity: int

@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    request.state.request_id = str(uuid.uuid4())
    response = await call_next(request)
    response.headers["x-request-id"] = request.state.request_id
    return response

@app.get("/health")
def health():
    return {"ok": True, "version": app.version}

@app.get("/api/v1/items", response_model=List[Item])
def list_items(request: Request):
    key = require_key(request)
    rate_limit(key)
    with get_conn() as conn:
        rows = conn.execute("SELECT name, sku, quantity FROM items").fetchall()
    return [dict(r) for r in rows]

@app.post("/api/v1/items")
def create_item(request: Request, item: Item):
    key = require_key(request)
    rate_limit(key)
    with get_conn() as conn:
        try:
            conn.execute("INSERT INTO items(name, sku, quantity) VALUES(?,?,?)",
                         (item.name, item.sku, item.quantity))
            conn.commit()
        except:
            raise HTTPException(status_code=409, detail="duplicate_sku")
    return {"ok": True}

@app.get("/api/v1/export")
def export_csv(request: Request):
    key = require_key(request)
    rate_limit(key)
    with get_conn() as conn:
        rows = conn.execute("SELECT name, sku, quantity FROM items").fetchall()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["name","sku","quantity"])
    for r in rows:
        writer.writerow([r["name"], r["sku"], r["quantity"]])

    return {"csv": output.getvalue()}

@app.post("/api/v1/import")
def import_csv(request: Request, payload: dict):
    key = require_key(request)
    rate_limit(key)
    data = payload.get("csv","")
    reader = csv.DictReader(io.StringIO(data))
    inserted = 0
    with get_conn() as conn:
        for row in reader:
            try:
                conn.execute("INSERT INTO items(name, sku, quantity) VALUES(?,?,?)",
                             (row["name"], row["sku"], int(row["quantity"])))
                inserted += 1
            except:
                pass
        conn.commit()
    return {"inserted": inserted}

@app.get("/admin", response_class=HTMLResponse)
def admin_ui():
    return """
    <h2>Inventory Admin</h2>
    <p>Use API endpoints with x-api-key header.</p>
    <p>Docs: <a href='/docs'>Swagger UI</a></p>
    """
PY

# ---------------- tests ----------------
cat > "$APP/tests/test_v5.py" <<'PY'
from fastapi.testclient import TestClient
from app.main import app
import os

os.environ["INVENTORY_API_KEY"] = "test-key"

client = TestClient(app)
H = {"x-api-key":"test-key"}

def test_flow():
    r = client.get("/health")
    assert r.status_code == 200

    r = client.post("/api/v1/items", headers=H,
                    json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 200

    r = client.get("/api/v1/items", headers=H)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/api/v1/export", headers=H)
    assert "csv" in r.json()
PY

# ---------------- Makefile ----------------
cat > "$APP/Makefile" <<'MK'
SHELL := /bin/bash
venv:
python3 -m venv .venv
install:
. .venv/bin/activate && pip install -r requirements.txt
test:
. .venv/bin/activate && pytest -q
run:
. .venv/bin/activate && uvicorn app.main:app --host 127.0.0.1 --port 9000
MK

echo "Installing..."
cd "$APP"
python3 -m venv .venv >/dev/null 2>&1 || true
. .venv/bin/activate
pip install -U pip >/dev/null
pip install -r requirements.txt >/dev/null
pytest -q

echo
echo "🎉 v5 Enterprise ready"
echo "Run:"
echo "  cd $APP"
echo "  export INVENTORY_API_KEY=your-key"
echo "  make run"
echo
echo "Access:"
echo "  http://127.0.0.1:9000/docs"
