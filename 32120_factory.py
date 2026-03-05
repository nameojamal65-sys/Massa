from .memory import MemoryStore
from .sqlite import SQLiteStore

def get_store(kind="memory", **kw):
    if kind == "memory":
        return MemoryStore()
    if kind == "sqlite":
        return SQLiteStore(kw.get("path","data.db"))
    raise ValueError("Unsupported store type")
