import os, hmac, hashlib
KEY_FILE = "security/platform_key.txt"

def ensure_key():
    os.makedirs("security", exist_ok=True)
    if not os.path.exists(KEY_FILE):
        with open(KEY_FILE, "w", encoding="utf-8") as f:
            f.write(os.urandom(32).hex())

def _key() -> bytes:
    ensure_key()
    with open(KEY_FILE,"r",encoding="utf-8") as f:
        return bytes.fromhex(f.read().strip())

def sign(payload: str) -> str:
    return hmac.new(_key(), payload.encode("utf-8"), hashlib.sha256).hexdigest()

def verify(payload: str, sig: str) -> bool:
    return hmac.compare_digest(sign(payload), sig or "")
