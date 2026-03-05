import yaml
from core.config import Settings
from commercial.metering import today

def _plans():
    with open(Settings.PLANS_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def check(tenant: str, plan: str, kind: str) -> (bool, dict):
    plans = _plans().get("plans",{})
    quota = (plans.get(plan,{}) or {}).get("quota",{})
    usage = today(tenant)
    if kind == "gpu":
        limit = int(quota.get("gpu_jobs_per_day", 0))
        return (usage["gpu_jobs"] < limit, {"limit": limit, "usage": usage})
    limit = int(quota.get("jobs_per_day", 0))
    return (usage["jobs"] < limit, {"limit": limit, "usage": usage})
