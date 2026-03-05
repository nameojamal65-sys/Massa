import os
def flag(name: str, default: str="0") -> bool:
    return os.getenv(name, default).strip() in ("1","true","True","yes","YES")
SC_OPS_API = flag("SC_OPS_API", "0")   # master switch for /api/ops/*
