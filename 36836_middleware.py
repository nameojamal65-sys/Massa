import uuid
from flask import request, g, jsonify
from sc_platform.flags import SC_VERSION, SC_FREEZE
from sc_platform.errors import to_json, SCError

CORR_HEADER_IN = "X-Correlation-Id"
CORR_HEADER_OUT = "X-Correlation-Id"
VER_HEADER_OUT = "X-SC-Version"

FREEZE_ALLOWLIST_PREFIXES = (
    "/health",
    "/api/status",
    "/api/audit/verify",
)


def install(app):
    @app.before_request
    def _corr_and_freeze():
        cid = request.headers.get(CORR_HEADER_IN) or str(uuid.uuid4())
        g.correlation_id = cid

        if SC_FREEZE and request.method in ("POST", "PUT", "PATCH", "DELETE"):
            path = request.path or ""
            if not path.startswith(FREEZE_ALLOWLIST_PREFIXES):
                raise SCError(
                    "MAINTENANCE_MODE",
                    "System is in maintenance mode",
                    status=503)

    @app.after_request
    def _headers(resp):
        cid = getattr(g, "correlation_id", None)
        if cid:
            resp.headers[CORR_HEADER_OUT] = cid
        resp.headers[VER_HEADER_OUT] = SC_VERSION
        return resp

    @app.errorhandler(Exception)
    def _handle(err):
        cid = getattr(g, "correlation_id", "-")
        payload, status = to_json(err, cid)
        return jsonify(payload), status
