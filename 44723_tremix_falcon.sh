#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ============ Tremix Falcon v1 ============
BASE="$HOME/TremixProduct"
TS="$(date +%Y%m%d_%H%M%S)"
APP="$BASE/apps/inventory_api_$TS"
PORT="${PORT:-9000}"

say(){ echo -e "🦅 $*"; }

say "Falcon v1 starting..."
say "Target: $APP"

mkdir -p "$APP/app" "$APP/tests"

# -------- Write files (REAL product) --------
cat > "$APP/requirements.txt" <<'EOF'
fastapi
uvicorn
pydantic
pytest
httpx
EOF

cat > "$APP/app/__init__.py" <<'EOF'
EOF

cat > "$APP/app/main.py" <<'EOF'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, List
import time

app = FastAPI(title="Inventory API", version="1.0.0")

class ItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    sku: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=0, le=1_000_000)

class Item(ItemIn):
    id: int

_DB: Dict[int, Item] = {}
_NEXT_ID = 1

def _now_ms() -> int:
    return int(time.time() * 1000)

@app.get("/health")
def health():
    return {"ok": True, "items": len(_DB), "ts_ms": _now_ms()}

@app.get("/items", response_model=List[Item])
def list_items():
    return list(_DB.values())

@app.post("/items", response_model=Item, status_code=201)
def create_item(payload: ItemIn):
    global _NEXT_ID
    for it in _DB.values():
        if it.sku == payload.sku:
            raise HTTPException(status_code=409, detail="SKU already exists")
    item = Item(id=_NEXT_ID, **payload.model_dump())
    _DB[_NEXT_ID] = item
    _NEXT_ID += 1
    return item

@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int):
    item = _DB.get(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@app.put("/items/{item_id}", response_model=Item)
def update_item(item_id: int, payload: ItemIn):
    if item_id not in _DB:
        raise HTTPException(status_code=404, detail="Item not found")
    for it_id, it in _DB.items():
        if it_id != item_id and it.sku == payload.sku:
            raise HTTPException(status_code=409, detail="SKU already exists")
    item = Item(id=item_id, **payload.model_dump())
    _DB[item_id] = item
    return item

@app.delete("/items/{item_id}", status_code=204)
def delete_item(item_id: int):
    if item_id not in _DB:
        raise HTTPException(status_code=404, detail="Item not found")
    _DB.pop(item_id, None)
    return None
EOF

cat > "$APP/tests/test_inventory.py" <<'EOF'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True

def test_crud_flow():
    r = client.post("/items", json={"name":"Keyboard","sku":"KB-001","quantity":5})
    assert r.status_code == 201
    item = r.json()
    assert item["id"] == 1

    r = client.get("/items")
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/items/1")
    assert r.status_code == 200

    r = client.put("/items/1", json={"name":"Keyboard Pro","sku":"KB-001","quantity":7})
    assert r.status_code == 200
    assert r.json()["quantity"] == 7

    r = client.post("/items", json={"name":"Mouse","sku":"KB-001","quantity":1})
    assert r.status_code == 409

    r = client.delete("/items/1")
    assert r.status_code == 204

    r = client.get("/items/1")
    assert r.status_code == 404
EOF

cat > "$APP/README.md" <<EOF
# Inventory API (Falcon v1)

## Run
\`\`\`bash
source .venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port $PORT
\`\`\`

## Endpoints
- GET  /health
- GET  /items
- POST /items
- GET  /items/{id}
- PUT  /items/{id}
- DELETE /items/{id}
EOF

# -------- Build: venv + deps --------
say "Installing deps..."
cd "$APP"

python3 -m venv .venv
PIP="$APP/.venv/bin/pip"
PYTEST="$APP/.venv/bin/pytest"
UVICORN="$APP/.venv/bin/uvicorn"

"$PIP" install -U pip >/dev/null
"$PIP" install -r requirements.txt >/dev/null

# -------- Test --------
say "Running tests..."
set +e
OUT="$("$PYTEST" -q 2>&1)"
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
  echo "❌ Tests failed:"
  echo "$OUT"
  echo
  echo "📁 Project kept at: $APP"
  exit 1
fi

say "Tests passed ✅"

# -------- Run --------
# Port fallback if busy
if python3 - <<PY >/dev/null 2>&1; then
import socket
s=socket.socket(); s.settimeout(0.2)
try:
    s.connect(("127.0.0.1", int("$PORT")))
    raise SystemExit(1)
except Exception:
    raise SystemExit(0)
PY
then
  :
else
  PORT=$((PORT+1))
fi

LOG="$APP/run.log"
say "Starting server on http://127.0.0.1:$PORT"
nohup "$UVICORN" app.main:app --host 127.0.0.1 --port "$PORT" > "$LOG" 2>&1 & disown

sleep 0.5
say "DONE"
echo "📁 Project: $APP"
echo "🌐 URL: http://127.0.0.1:$PORT"
echo "🧾 Log: $LOG"
echo
echo "Try:"
echo "  curl -s http://127.0.0.1:$PORT/health"
echo "  curl -s http://127.0.0.1:$PORT/items"
