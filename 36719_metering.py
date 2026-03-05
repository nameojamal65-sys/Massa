import os, json, time
from core.config import Settings

METER_DB = "data/metering.json"

def _ensure():
    os.makedirs(os.path.dirname(METER_DB), exist_ok=True)
    if not os.path.exists(METER_DB):
        with open(METER_DB,"w",encoding="utf-8") as f:
            json.dump({"by_tenant":{}}, f, ensure_ascii=False, indent=2)

def _load():
    _ensure()
    with open(METER_DB,"r",encoding="utf-8") as f:
        return json.load(f)

def _save(db):
    _ensure()
    with open(METER_DB,"w",encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

def _day_key(ts=None):
    ts = ts or time.time()
    return time.strftime("%Y-%m-%d", time.localtime(ts))

def inc(tenant: str, kind: str):
    db = _load()
    day = _day_key()
    t = db["by_tenant"].setdefault(tenant, {})
    d = t.setdefault(day, {"jobs":0, "gpu_jobs":0})
    if kind == "gpu":
        d["gpu_jobs"] += 1
    else:
        d["jobs"] += 1
    _save(db)

def today(tenant: str):
    db = _load()
    day = _day_key()
    return (db["by_tenant"].get(tenant,{}) or {}).get(day, {"jobs":0,"gpu_jobs":0})
