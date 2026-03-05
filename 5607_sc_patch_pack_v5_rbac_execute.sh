#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_core"
OPS="$ROOT/sc_ops"
UI="$ROOT/ui/server.py"

echo "== Patch Pack v5: RBAC + Execute restart after approval (Zero-Break) =="

[ -d "$ROOT" ] || { echo "❌ missing $ROOT"; exit 1; }
[ -d "$OPS" ]  || { echo "❌ missing $OPS (install v3/v4 first)"; exit 1; }
[ -f "$UI" ]   || { echo "❌ missing $UI"; exit 1; }

# --- 1) Update HITL gate to allow bypass header ---
cat > "$OPS/hitl.py" <<'PY'
from flask import request, jsonify, g
from .flags import SC_HITL
from .store import get_store

BYPASS_HEADER = "X-SC-Bypass-HITL"

def install(app):
    @app.before_request
    def gate_restart():
        # Allow internal bypass to prevent loops
        if request.headers.get(BYPASS_HEADER) == "1":
            return None

        # Zero-break: only affects /api/restart when SC_HITL=1
        if not SC_HITL:
            return None

        if request.path == "/api/restart" and request.method in ("POST","PUT","PATCH","DELETE"):
            store = get_store()
            cid = getattr(g, "correlation_id", "-")
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

# --- 2) Add RBAC helper ---
cat > "$OPS/rbac.py" <<'PY'
from flask import request, jsonify, g
from .flags import SC_ADMIN_KEY

def require_admin():
    # If SC_ADMIN_KEY not set, we allow (RC mode). Set it in prod.
    if not SC_ADMIN_KEY:
        return None
    key = request.headers.get("X-API-Key", "")
    if key != SC_ADMIN_KEY:
        return jsonify({
            "ok": False,
            "error": {"code":"FORBIDDEN","message":"Admin key required","details":{}},
            "correlation_id": getattr(g, "correlation_id", "-")
        }), 403
    return None
PY

# --- 3) Add internal action executor ---
cat > "$OPS/actions.py" <<'PY'
import json, urllib.request
from typing import Tuple, Dict, Any
from .store import get_store

BYPASS_HEADER = "X-SC-Bypass-HITL"

def _post(url: str, body: Dict[str, Any], headers: Dict[str, str]) -> Tuple[int, str]:
    data = json.dumps(body or {}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=10) as r:
        return r.status, r.read().decode("utf-8", errors="ignore")

def execute_restart(base_url: str = "http://127.0.0.1:8080") -> Dict[str, Any]:
    store = get_store()
    # Call legacy restart endpoint internally with bypass header
    status, text = _post(
        f"{base_url}/api/restart",
        {},
        {"Content-Type":"application/json", BYPASS_HEADER:"1", "X-Client":"sc_ops"},
    )
    if 200 <= status < 300:
        store._audit("action.executed", job_id=None, data={"action":"restart","status":status})
        return {"ok": True, "status": status, "response": text[:4000]}
    store._audit("action.failed", job_id=None, data={"action":"restart","status":status,"response":text[:4000]})
    return {"ok": False, "status": status, "response": text[:4000]}
PY

# --- 4) Update sc_ops/api.py: protect decision endpoint + execute restart on approve ---
cat > "$OPS/api.py" <<'PY'
from flask import Blueprint, jsonify, request, g, Response
import json, time
from .flags import SC_OPS_API
from .store import get_store
from .rbac import require_admin
from .actions import execute_restart

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
    # optional: lock this too, but leaving open for RC
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
    # RBAC: require admin for decisions
    deny = require_admin()
    if deny: return deny

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

    # Execute sensitive actions only when approved
    exec_result = None
    if status == "approved":
        action = (a.payload or {}).get("action")
        if action == "restart":
            exec_result = execute_restart()

    return jsonify({"ok": True, "approval": a.to_dict(), "executed": exec_result})

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

echo "✅ v5 applied (files updated)."
echo ""
echo "Enable:"
echo "  export SC_OPS_API=1"
echo "  export SC_HITL=1"
echo "  export SC_ADMIN_KEY='your-strong-key'"
echo ""
echo "Flow:"
echo "  1) POST /api/restart  -> returns 202 + approval_id"
echo "  2) Approve via: POST /api/ops/approvals/<id>/decision {status:approved} with X-API-Key"
echo "  3) System executes /api/restart internally (bypass) + audit logs"
