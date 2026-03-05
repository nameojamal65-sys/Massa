import yaml
from core.config import Settings

def load_policy():
    with open(Settings.POLICY_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def is_denied(action: str) -> bool:
    p = load_policy().get("policy",{})
    for rule in p.get("deny",[]) or []:
        if rule.get("action") == action:
            return True
    return False

def is_allowed(action: str, role: str) -> bool:
    p = load_policy().get("policy",{})
    for rule in p.get("allow",[]) or []:
        if rule.get("action") == action and role in (rule.get("roles") or []):
            return True
    return False

def diffusion_requires_admin() -> bool:
    p = load_policy().get("policy",{})
    d = p.get("diffusion") or {}
    return (d.get("requires_role","admin") == "admin")
