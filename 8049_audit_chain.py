import os, json, hashlib, time
from core.config import Settings

def _ensure_dir():
    os.makedirs(os.path.dirname(Settings.AUDIT_LOG), exist_ok=True)

def _hash(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()

def append(event: dict):
    """Append-only chained audit log (tamper-evident)."""
    _ensure_dir()
    prev_hash = "0"*64
    if os.path.exists(Settings.AUDIT_LOG):
        with open(Settings.AUDIT_LOG, "r", encoding="utf-8") as f:
            lines = [ln.strip() for ln in f.readlines() if ln.strip()]
        if lines:
            try:
                last = json.loads(lines[-1])
                prev_hash = last.get("hash","0"*64)
            except Exception:
                prev_hash = "0"*64

    rec = {
        "ts": time.time(),
        "prev_hash": prev_hash,
        "event": event,
    }
    payload = json.dumps(rec, ensure_ascii=False, sort_keys=True)
    rec["hash"] = _hash(payload)

    with open(Settings.AUDIT_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")

def verify() -> dict:
    if not os.path.exists(Settings.AUDIT_LOG):
        return {"ok": True, "records": 0}
    with open(Settings.AUDIT_LOG,"r",encoding="utf-8") as f:
        lines = [ln.strip() for ln in f if ln.strip()]
    prev = "0"*64
    for i, ln in enumerate(lines):
        rec = json.loads(ln)
        if rec.get("prev_hash") != prev:
            return {"ok": False, "at": i, "reason": "prev_hash_mismatch"}
        chk = dict(rec)
        h = chk.pop("hash")
        payload = json.dumps(chk, ensure_ascii=False, sort_keys=True)
        if hashlib.sha256(payload.encode("utf-8")).hexdigest() != h:
            return {"ok": False, "at": i, "reason": "hash_mismatch"}
        prev = h
    return {"ok": True, "records": len(lines)}
