import os
import traceback
from dataclasses import dataclass
from typing import Any, Dict, Optional


def _debug_enabled() -> bool:
    return os.getenv("SC_DEBUG_ERRORS", "0").strip() in ("1","true","True","yes","YES")
@dataclass
class SCError(Exception):
    code: str
    message: str
    status: int = 400
    details: Optional[Dict[str, Any]] = None

def to_json(err: Exception, correlation_id: str):
    DEBUG = _debug_enabled()
    if isinstance(err, SCError):
        payload = {
            "ok": False,
            "error": {
                "code": err.code,
                "message": err.message,
                "details": err.details or {},
            },
            "correlation_id": correlation_id,
        }
        return payload, err.status

    details: Dict[str, Any] = {}
    if DEBUG:
        details = {
            "type": type(err).__name__,
            "repr": repr(err),
            "traceback": traceback.format_exc(),
        }
payload = {
        "ok": False,
        "error": {
            "code": "INTERNAL_ERROR",
            "message": "Unexpected server error",
            "details": details,
        },
        "correlation_id": correlation_id,
    }
    return payload, 500
