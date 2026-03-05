import os, json, secrets, hashlib
from core.config import Settings

def _ensure():
    os.makedirs(os.path.dirname(Settings.IDENTITY_DB), exist_ok=True)
    if not os.path.exists(Settings.IDENTITY_DB):
        with open(Settings.IDENTITY_DB, "w", encoding="utf-8") as f:
            json.dump({"users": {}, "tokens": {}, "tenants": {}}, f, ensure_ascii=False, indent=2)

def _load():
    _ensure()
    with open(Settings.IDENTITY_DB, "r", encoding="utf-8") as f:
        return json.load(f)

def _save(db):
    _ensure()
    with open(Settings.IDENTITY_DB, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

def _phash(pw: str) -> str:
    return hashlib.sha256(pw.encode("utf-8")).hexdigest()

def bootstrap_admin():
    db = _load()
    if "admin" in db["users"]:
        return
    db["users"]["admin"] = {"password_hash": _phash("admin"), "role": "admin"}
    _save(db)

def login(user: str, password: str) -> str | None:
    db = _load()
    u = db["users"].get(user)
    if not u or u.get("password_hash") != _phash(password):
        return None
    token = secrets.token_hex(24)
    db["tokens"][token] = {"user": user, "role": u.get("role","operator")}
    _save(db)
    return token

def whoami(token: str):
    db = _load()
    return db["tokens"].get(token)

def require_token(token: str):
    info = whoami(token)
    if not info:
        raise PermissionError("invalid_token")
    return info

def create_tenant(name: str, plan: str="free"):
    db = _load()
    if name in db["tenants"]:
        return db["tenants"][name]
    db["tenants"][name] = {"tenant": name, "plan": plan, "created": True}
    _save(db)
    return db["tenants"][name]

def list_tenants():
    db = _load()
    return db["tenants"]
