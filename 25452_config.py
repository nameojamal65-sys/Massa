import os
def api_key() -> str: return os.environ.get("INVENTORY_API_KEY", "dev-key-change-me")
def db_path() -> str: return os.environ.get("INVENTORY_DB", os.path.abspath("inventory.db"))
def rate_limit_per_minute() -> int: return int(os.environ.get("INVENTORY_RL_PER_MIN", "120"))
def log_path() -> str: return os.environ.get("INVENTORY_LOG", os.path.abspath("inventory.log"))
