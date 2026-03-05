from flask import Blueprint, jsonify, request, g, Response
import json
import time
from sc_platform.flags import SC_OPS_API
from sc_platform.store import get_store
from sc_platform.rbac import require_admin
from sc_platform.actions import execute_restart

bp = Blueprint("sc_ops", __name__)


def _not_found():
    return jsonify({"ok": False, "error": {"code": "OPS_DISABLED", "message": "SC_OPS_API is disabled",
                   "details": {}}, "correlation_id": getattr(g, "correlation_id", "-")}), 404


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
    title = payload.get("title", "")
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
        return jsonify(
            {
                "ok": False, "error": {
                    "code": "NOT_FOUND", "message": "job not found", "details": {
                        "job_id": job_id}}, "correlation_id": getattr(
                    g, "correlation_id", "-")}), 404
    return jsonify({"ok": True, "job": j.to_dict()})


@bp.post("/api/ops/approvals")
def create_approval():
    # optional: lock this too, but leaving open for RC
    payload = request.get_json(force=True, silent=True) or {}
    job_id = payload.get("job_id")
    reason = payload.get("reason", "")
    store = get_store()
    a = store.create_approval(
        job_id=job_id,
        reason=reason,
        payload=payload.get("payload") or {})
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
    if deny:
        return deny

    payload = request.get_json(force=True, silent=True) or {}
    status = payload.get("status", "").lower()
    if status not in ("approved", "rejected"):
        return jsonify({"ok": False, "error": {"code": "BAD_REQUEST", "message": "status must be approved|rejected",
                       "details": {}}, "correlation_id": getattr(g, "correlation_id", "-")}), 400

    store = get_store()
    a = store.set_approval(approval_id, status)
    if not a:
        return jsonify(
            {
                "ok": False, "error": {
                    "code": "NOT_FOUND", "message": "approval not found", "details": {
                        "approval_id": approval_id}}, "correlation_id": getattr(
                    g, "correlation_id", "-")}), 404

    # Execute sensitive actions only when approved
    exec_result = None
    if status == "approved":
        action = (a.payload or {}).get("action")
        if action == "restart":
            exec_result = execute_restart()

    return jsonify({"ok": True,
                    "approval": a.to_dict(),
                    "executed": exec_result})


@bp.get("/api/ops/audit")
def audit():
    store = get_store()
    limit = int(request.args.get("limit", "200"))
    events = [e.to_dict() for e in store.list_audit(limit=limit)]
    return jsonify({"ok": True, "events": events})


@bp.get("/api/ops/audit/verify")
def audit_verify():
    store = get_store()
    if hasattr(store, "verify_audit_chain"):
        return jsonify(
            store.verify_audit_chain(
                limit=int(
                    request.args.get(
                        "limit",
                        "500"))))
    return jsonify(
        {"ok": True, "note": "memory store has no hash chain verify", "checked": 0})


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
