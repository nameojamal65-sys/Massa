import time
from typing import Dict, Tuple
from fastapi import HTTPException, Request
from app.config import api_key, rate_limit_per_minute
from app.logging_utils import log

_BUCKETS: Dict[str, Tuple[float, float]] = {}  # key -> (tokens, last_ts)

def require_api_key(request: Request) -> str:
    k = request.headers.get("x-api-key", "")
    if not k or k != api_key():
        log("auth_failed", ip=getattr(request.client, "host", ""), path=str(request.url.path))
        raise HTTPException(status_code=401, detail="unauthorized")
    return k

def rate_limit(key: str):
    cap = float(rate_limit_per_minute())
    refill_per_sec = cap / 60.0
    now = time.time()
    tokens, last = _BUCKETS.get(key, (cap, now))
    tokens = min(cap, tokens + (now - last) * refill_per_sec)
    if tokens < 1.0:
        raise HTTPException(status_code=429, detail="rate_limited")
    tokens -= 1.0
    _BUCKETS[key] = (tokens, now)
