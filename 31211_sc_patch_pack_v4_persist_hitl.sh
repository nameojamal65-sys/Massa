#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_core"
UI="$ROOT/ui/server.py"
OPS="$ROOT/sc_ops"
STORE="$OPS/store"

echo "== Patch Pack v4: SQLite persistence + HITL gate + Audit verify (Zero-Break) =="

[ -d "$ROOT" ] || { echo "❌ لم أجد $ROOT"; exit 1; }
[ -f "$UI" ] || { echo "❌ لم أجد $UI"; exit 1; }
[ -d "$OPS" ] || { echo "❌ لم أجد $OPS (ركّب v3 أولًا)"; exit 1; }

mkdir -p "$STORE"

# -------- flags ----------
cat > "$OPS/flags.py" <<'PY'
import os
def flag(name: str, default: str="0") -> bool:
    return os.getenv(name, default).strip() in ("1","true","True","yes","YES")

SC_OPS_API = flag("SC_OPS_API", "0")         # /api/ops/*
SC_OPS_DB  = os.getenv("SC_OPS_DB", "sqlite").strip()  # sqlite|memory
SC_DB_PATH = os.getenv("SC_DB_PATH", os.path.join(os.path.dirname(__file__), "store", "sc_ops.sqlite3"))

SC_HITL    = flag("SC_HITL", "0")            # gate /api/restart
SC_ADMIN_KEY = os.getenv("SC_ADMIN_KEY", "").strip()   # optional simple auth
PY

# -------- sqlite store ----------
cat > "$STORE/sqlite.py" <<'PY'
import sqlite3, json, time, os, hashlib
from typing import List, Optional, Dict, Any
from ..models import Job, Approval, AuditEvent, now_ms
from ..flags import SC_DB_PATH

def _connect():
    os.makedirs(os.path.dirname(SC_DB_PATH), exist_ok=True)
    conn = sqlite3.connect(SC_DB_PATH)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    return conn

def _init(conn):
    conn.execute("""
    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      created_at INTEGER,
      updated_at INTEGER,
      status TEXT,
      title TEXT,
      request_json TEXT,
      result_json TEXT,
      error TEXT,
      correlation_id TEXT
    )""")
    conn.execute("""
    CREATE TABLE IF NOT EXISTS approvals (
      id TEXT PRIMARY KEY,
      created_at INTEGER,
      status TEXT,
      job_id TEXT,
      reason TEXT,
      payload_json TEXT
    )""")
    conn.execute("""
    CREATE TABLE IF NOT EXISTS audit (
      id TEXT PRIMARY KEY,
      ts INTEGER,
      kind TEXT,
      actor TEXT,
      job_id TEXT,
      data_json TEXT,
      prev_hash TEXT,
      hash TEXT
    )""")
    conn.execute("""
    CREATE TABLE IF NOT EXISTS tenants (
      id TEXT PRIMARY KEY,
      plan TEXT,
      quota_daily_jobs INTEGER,
      used_jobs_today INTEGER
    )""")
    conn.commit()

def _hash_event(prev_hash: str, ev: Dict[str, Any]) -> str:
    h = hashlib.sha256()
    h.update((prev_hash or "").encode("utf-8"))
    h.update(json.dumps(ev, sort_keys=True, ensure_ascii=False).encode("utf-8"))
    return h.hexdigest()

class SQLiteStore:
    def __init__(self):
        self.conn = _connect()
        _init(self.conn)
        # ensure default tenant
        cur = self.conn.execute("SELECT id FROM tenants WHERE id='default'")
        if not cur.fetchone():
            self.conn.execute("INSERT INTO tenants(id,plan,quota_daily_jobs,used_jobs_today) VALUES (?,?,?,?)",
                              ("default","rc",200,0))
            self.conn.commit()

    # ----- audit chain helpers -----
    def _last_hash(self) -> str:
        cur = self.conn.execute("SELECT hash FROM audit ORDER BY ts DESC LIMIT 1")
        row = cur.fetchone()
        return row[0] if row else ""

    def _audit(self, kind: str, job_id: str=None, data: dict=None, actor: str="system"):
        ev = AuditEvent(kind=kind, actor=actor, job_id=job_id, data=data or {})
        evd = ev.to_dict()
        prev = self._last_hash()
        h = _hash_event(prev, evd)
        self.conn.execute(
            "INSERT INTO audit(id,ts,kind,actor,job_id,data_json,prev_hash,hash) VALUES (?,?,?,?,?,?,?,?)",
            (ev.id, ev.ts, ev.kind, ev.actor, ev.job_id, json.dumps(evd["data"], ensure_ascii=False), prev, h)
        )
        self.conn.commit()

    def verify_audit_chain(self, limit: int=500) -> dict:
        cur = self.conn.execute("SELECT id,ts,kind,actor,job_id,data_json,prev_hash,hash FROM audit ORDER BY ts ASC LIMIT ?", (limit,))
        rows = cur.fetchall()
        prev = ""
        ok = True
        bad_at = None
        for r in rows:
            evd = {
                "id": r[0], "ts": r[1], "kind": r[2], "actor": r[3], "job_id": r[4],
                "data": json.loads(r[5] or "{}")
            }
            expect = _hash_event(prev, evd)
            if (r[6] or "") != prev or (r[7] or "") != expect:
                ok = False
                bad_at = r[0]
                break
            prev = r[7] or ""
        return {"ok": ok, "checked": len(rows), "bad_at": bad_at}

    # ----- tenants -----
    def get_tenants(self):
        cur = self.conn.execute("SELECT id,plan,quota_daily_jobs,used_jobs_today FROM tenants")
        return [{"id":r[0],"plan":r[1],"quota_daily_jobs":r[2],"used_jobs_today":r[3]} for r in cur.fetchall()]

    def _inc_jobs_today(self):
        self.conn.execute("UPDATE tenants SET used_jobs_today = used_jobs_today + 1 WHERE id='default'")
        self.conn.commit()

    # ----- jobs -----
    def create_job(self, title: str, request: dict, correlation_id: str) -> Job:
        j = Job(title=title, request=request or {}, correlation_id=correlation_id)
        self.conn.execute(
            "INSERT INTO jobs(id,created_at,updated_at,status,title,request_json,result_json,error,correlation_id) VALUES (?,?,?,?,?,?,?,?,?)",
            (j.id, j.created_at, j.updated_at, j.status, j.title,
             json.dumps(j.request, ensure_ascii=False), json.dumps(j.result, ensure_ascii=False), j.error, j.correlation_id)
        )
        self.conn.commit()
        self._audit("job.created", job_id=j.id, data={"title": title})
        self._inc_jobs_today()
        return j

    def list_jobs(self) -> List[Job]:
        cur = self.conn.execute("SELECT id,created_at,updated_at,status,title,request_json,result_json,error,correlation_id FROM jobs ORDER BY created_at DESC LIMIT 500")
        out=[]
        for r in cur.fetchall():
            j = Job(id=r[0], created_at=r[1], updated_at=r[2], status=r[3], title=r[4],
                    request=json.loads(r[5] or "{}"), result=json.loads(r[6] or "{}"), error=r[7], correlation_id=r[8])
            out.append(j)
        return out

    def get_job(self, job_id: str) -> Optional[Job]:
        cur = self.conn.execute("SELECT id,created_at,updated_at,status,title,request_json,result_json,error,correlation_id FROM jobs WHERE id=?", (job_id,))
        r = cur.fetchone()
        if not r: return None
        return Job(id=r[0], created_at=r[1], updated_at=r[2], status=r[3], title=r[4],
                   request=json.loads(r[5] or "{}"), result=json.loads(r[6] or "{}"), error=r[7], correlation_id=r[8])

    def update_job_status(self, job_id: str, status: str, result: dict=None, error: str=None):
        j = self.get_job(job_id)
        if not j: return None
        j.status = status
        j.updated_at = now_ms()
        if result is not None: j.result = result
        if error is not None: j.error = error
        self.conn.execute("UPDATE jobs SET updated_at=?, status=?, result_json=?, error=? WHERE id=?",
                          (j.updated_at, j.status, json.dumps(j.result, ensure_ascii=False), j.error, j.id))
        self.conn.commit()
        self._audit("job.updated", job_id=j.id, data={"status": status})
        return j

    # ----- approvals -----
    def create_approval(self, job_id: str, reason: str, payload: dict=None) -> Approval:
        a = Approval(job_id=job_id, reason=reason or "", payload=payload or {})
        self.conn.execute(
            "INSERT INTO approvals(id,created_at,status,job_id,reason,payload_json) VALUES (?,?,?,?,?,?)",
            (a.id, a.created_at, a.status, a.job_id, a.reason, json.dumps(a.payload, ensure_ascii=False))
        )
        self.conn.commit()
        self._audit("approval.created", job_id=job_id, data={"approval_id": a.id})
        return a

    def list_approvals(self) -> List[Approval]:
        cur = self.conn.execute("SELECT id,created_at,status,job_id,reason,payload_json FROM approvals ORDER BY created_at DESC LIMIT 500")
        out=[]
        for r in cur.fetchall():
            a = Approval(id=r[0], created_at=r[1], status=r[2], job_id=r[3], reason=r[4], payload=json.loads(r[5] or "{}"))
            out.append(a)
        return out

    def set_approval(self, approval_id: str, status: str):
        cur = self.conn.execute("SELECT id,created_at,status,job_id,reason,payload_json FROM approvals WHERE id=?", (approval_id,))
        r = cur.fetchone()
        if not r: return None
        self.conn.execute("UPDATE approvals SET status=? WHERE id=?", (status, approval_id))
        self.conn.commit()
        a = Approval(id=r[0], created_at=r[1], status=status, job_id=r[3], reason=r[4], payload=json.loads(r[5] or "{}"))
        self._audit("approval.updated", job_id=a.job_id, data={"approval_id": a.id, "status": status})
        return a

    # ----- audit list -----
    def list_audit(self, limit: int=200) -> List[AuditEvent]:
        cur = self.conn.execute("SELECT id,ts,kind,actor,job_id,data_json,prev_hash,hash FROM audit ORDER BY ts DESC LIMIT ?", (limit,))
        out=[]
        for r in cur.fetchall():
            ev = AuditEvent(id=r[0], ts=r[1], kind=r[2], actor=r[3], job_id=r[4], data=json.loads(r[5] or "{}"))
            out.append(ev)
        return out
PY

# -------- store selector ----------
cat > "$STORE/__init__.py" <<'PY'
from ..flags import SC_OPS_DB
from .memory import STORE as MEM
try:
    from .sqlite import SQLiteStore
except Exception:
    SQLiteStore = None

_store = None

def get_store():
    global _store
    if _store is not None:
        return _store
    if SC_OPS_DB == "sqlite" and SQLiteStore is not None:
        _store = SQLiteStore()
    else:
        _store = MEM
    return _store
PY

# -------- HITL gate (for /api/restart) ----------
cat > "$OPS/hitl.py" <<'PY'
from flask import request, jsonify, g
from .flags import SC_HITL
from .store import get_store

def install(app):
    @app.before_request
    def gate_restart():
        # Zero-break: only affects /api/restart when SC_HITL=1
        if not SC_HITL:
            return None

        if request.path == "/api/restart" and request.method in ("POST","PUT","PATCH","DELETE"):
            store = get_store()
            cid = getattr(g, "correlation_id", "-")
            # Create an approval instead of restarting immediately
            job = store.create_job(title="restart", request={"path":"/api/restart"}, correlation_id=cid)
            approval = store.create_approval(job_id=job.id, reason="Restart requires approval", payload={"action":"restart"})
            return jsonify({
                "ok": True,
                "pending": True,
                "message": "Restart request captured; approval required.",
                "job_id": job.id,
                "approval_id": approval.id,
                "correlation_id": cid
            }), 202

        return None
PY

# -------- update sc_ops/api.py to use store selector + verify endpoint ----------
cat > "$OPS/api.py" <<'PY'
from flask import Blueprint, jsonify, request, g, Response
import json, time
from .flags import SC_OPS_API
from .store import get_store

bp = Blueprint("sc_ops", __name__)

def _not_found():
    return jsonify({"ok": False, "error": {"code":"OPS_DISABLED","message":"SC_OPS_API is disabled","details":{}},
                    "correlation_id": getattr(g, "correlation_id", "-")}), 404

@bp.before_request
def _guard():
    if not SC_OPS_API:
        return _not_found()

@bp.get("/api/ops/ping")
def ping():
    return jsonify({"ok": True, "service": "sc_ops", "enabled": True})

@bp.post("/api/ops/jobs")
def create_job():
    payload = request.get_json(force=True, silent=True) or {}
    title = payload.get("title","")
    req = payload.get("request", {})
    cid = getattr(g, "correlation_id", "-")
    store = get_store()
    j = store.create_job(title=title, request=req, correlation_id=cid)
    return jsonify({"ok": True, "job": j.to_dict()})

@bp.get("/api/ops/jobs")
def list_jobs():
    store = get_store()
    jobs = [j.to_dict() for j in store.list_jobs()]
    return jsonify({"ok": True, "jobs": jobs})

@bp.get("/api/ops/jobs/<job_id>")
def get_job(job_id: str):
    store = get_store()
    j = store.get_job(job_id)
    if not j:
        return jsonify({"ok": False, "error": {"code":"NOT_FOUND","message":"job not found","details":{"job_id":job_id}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 404
    return jsonify({"ok": True, "job": j.to_dict()})

@bp.post("/api/ops/approvals")
def create_approval():
    payload = request.get_json(force=True, silent=True) or {}
    job_id = payload.get("job_id")
    reason = payload.get("reason","")
    store = get_store()
    a = store.create_approval(job_id=job_id, reason=reason, payload=payload.get("payload") or {})
    return jsonify({"ok": True, "approval": a.to_dict()})

@bp.get("/api/ops/approvals")
def list_approvals():
    store = get_store()
    approvals = [a.to_dict() for a in store.list_approvals()]
    return jsonify({"ok": True, "approvals": approvals})

@bp.post("/api/ops/approvals/<approval_id>/decision")
def decide(approval_id: str):
    payload = request.get_json(force=True, silent=True) or {}
    status = payload.get("status","").lower()
    if status not in ("approved","rejected"):
        return jsonify({"ok": False, "error": {"code":"BAD_REQUEST","message":"status must be approved|rejected","details":{}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 400
    store = get_store()
    a = store.set_approval(approval_id, status)
    if not a:
        return jsonify({"ok": False, "error": {"code":"NOT_FOUND","message":"approval not found","details":{"approval_id":approval_id}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 404
    return jsonify({"ok": True, "approval": a.to_dict()})

@bp.get("/api/ops/audit")
def audit():
    store = get_store()
    limit = int(request.args.get("limit","200"))
    events = [e.to_dict() for e in store.list_audit(limit=limit)]
    return jsonify({"ok": True, "events": events})

@bp.get("/api/ops/audit/verify")
def audit_verify():
    store = get_store()
    if hasattr(store, "verify_audit_chain"):
        return jsonify(store.verify_audit_chain(limit=int(request.args.get("limit","500"))))
    return jsonify({"ok": True, "note": "memory store has no hash chain verify", "checked": 0})

@bp.get("/api/ops/tenants")
def tenants():
    store = get_store()
    return jsonify({"ok": True, "tenants": store.get_tenants()})

@bp.get("/api/ops/stream/status")
def stream_status():
    def gen():
        while True:
            data = {"ts": int(time.time()), "ok": True}
            yield f"event: heartbeat\ndata: {json.dumps(data)}\n\n"
            time.sleep(1)
    return Response(gen(), mimetype="text/event-stream")
PY

# -------- integrate HITL into ui/server.py (marker safe) ----------
python3 - <<'PY'
import pathlib, re
ui = pathlib.Path.home()/"sovereign_core"/"ui"/"server.py"
txt = ui.read_text(errors="ignore")

if "SC_HITL_BEGIN" in txt:
    print("✅ HITL already integrated.")
    raise SystemExit(0)

m = re.search(r'^\s*app\s*=\s*Flask\([^\n]*\)\s*$', txt, flags=re.M)
if not m:
    print("❌ لم أجد app = Flask(...) داخل ui/server.py"); raise SystemExit(1)

insert = r'''
# --- SC_HITL_BEGIN ---
# HITL gate for /api/restart (Zero-Break; default OFF)
try:
    from sc_ops.hitl import install as sc_install_hitl
    sc_install_hitl(app)
except Exception:
    pass
# --- SC_HITL_END ---
'''.lstrip("\n")

pos = m.end()
ui.write_text(txt[:pos] + "\n" + insert + txt[pos:])
print("✅ Integrated HITL gate into ui/server.py")
PY

echo "✅ v4 installed."
echo ""
echo "Enable (optional) persistence + ops + hitl:"
echo "  export SC_OPS_API=1"
echo "  export SC_OPS_DB=sqlite"
echo "  export SC_HITL=1"
echo ""
echo "Verify:"
echo "  curl -s http://127.0.0.1:8080/api/ops/ping"
echo "  curl -s http://127.0.0.1:8080/api/ops/audit/verify"
echo ""
echo "Test HITL restart (should return 202 when SC_HITL=1):"
echo "  curl -i -X POST http://127.0.0.1:8080/api/restart"
