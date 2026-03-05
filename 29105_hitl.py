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
