import os, json
from core.config import Settings
from platform_services.identity import create_tenant

def tenant_path(tenant: str):
    base = Settings.TENANT_DIR
    os.makedirs(base, exist_ok=True)
    tdir = os.path.join(base, tenant)
    os.makedirs(tdir, exist_ok=True)
    return tdir

def tenant_artifacts(tenant: str):
    adir = os.path.join(tenant_path(tenant), "artifacts")
    os.makedirs(adir, exist_ok=True)
    return adir

def ensure_tenant(tenant: str, plan: str="free"):
    create_tenant(tenant, plan=plan)
    return {"tenant": tenant, "plan": plan}
