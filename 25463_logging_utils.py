import json, time
from typing import Any, Dict
from app.config import log_path

def log(event: str, **fields: Any) -> None:
    rec: Dict[str, Any] = {"ts": int(time.time()), "event": event, **fields}
    with open(log_path(), "a", encoding="utf-8") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
