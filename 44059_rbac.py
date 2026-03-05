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
