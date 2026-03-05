import json
import urllib.request
from typing import Tuple, Dict, Any
from sc_platform.store import get_store

BYPASS_HEADER = "X-SC-Bypass-HITL"


def _post(url: str, body: Dict[str, Any],
          headers: Dict[str, str]) -> Tuple[int, str]:
    data = json.dumps(body or {}).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=10) as r:
        return r.status, r.read().decode("utf-8", errors="ignore")


def execute_restart(base_url: str = "http://127.0.0.1:8080") -> Dict[str, Any]:
    store = get_store()
    # Call legacy restart endpoint internally with bypass header
    status, text = _post(
        f"{base_url}/api/restart",
        {},
        {"Content-Type": "application/json", BYPASS_HEADER: "1", "X-Client": "sc_ops"},
    )
    if 200 <= status < 300:
        store._audit(
            "action.executed",
            job_id=None,
            data={
                "action": "restart",
                "status": status})
        return {"ok": True, "status": status, "response": text[:4000]}
    store._audit("action.failed", job_id=None, data={
                 "action": "restart", "status": status, "response": text[:4000]})
    return {"ok": False, "status": status, "response": text[:4000]}
