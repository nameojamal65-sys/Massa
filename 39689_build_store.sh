#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$HOME/sovereign_core/sc_ops/store"
mkdir -p "$BASE"

echo "🚀 Building Enterprise Storage Core..."

# ---------- base.py ----------
cat > "$BASE/base.py" <<'PY'
import threading
from abc import ABC, abstractmethod

class BaseStore(ABC):
    def __init__(self):
        self.lock = threading.RLock()

    @abstractmethod
    def get(self, key): ...
    @abstractmethod
    def set(self, key, value): ...
    @abstractmethod
    def delete(self, key): ...
    @abstractmethod
    def exists(self, key): ...
    @abstractmethod
    def all(self): ...
    @abstractmethod
    def close(self): ...
PY

# ---------- memory.py ----------
cat > "$BASE/memory.py" <<'PY'
from .base import BaseStore

class MemoryStore(BaseStore):
    def __init__(self):
        super().__init__()
        self.data = {}

    def get(self, key):
        return self.data.get(key)

    def set(self, key, value):
        self.data[key] = value

    def delete(self, key):
        self.data.pop(key, None)

    def exists(self, key):
        return key in self.data

    def all(self):
        return dict(self.data)

    def close(self):
        self.data.clear()
PY

# ---------- sqlite.py ----------
cat > "$BASE/sqlite.py" <<'PY'
import sqlite3, json, threading
from .base import BaseStore

class SQLiteStore(BaseStore):
    def __init__(self, path):
        super().__init__()
        self.conn = sqlite3.connect(path, check_same_thread=False)
        self.lock = threading.RLock()
        self.conn.execute("CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value TEXT)")
        self.conn.commit()

    def get(self, key):
        cur = self.conn.execute("SELECT value FROM kv WHERE key=?", (key,))
        row = cur.fetchone()
        return json.loads(row[0]) if row else None

    def set(self, key, value):
        self.conn.execute("INSERT OR REPLACE INTO kv VALUES (?,?)", (key, json.dumps(value)))
        self.conn.commit()

    def delete(self, key):
        self.conn.execute("DELETE FROM kv WHERE key=?", (key,))
        self.conn.commit()

    def exists(self, key):
        cur = self.conn.execute("SELECT 1 FROM kv WHERE key=?", (key,))
        return cur.fetchone() is not None

    def all(self):
        cur = self.conn.execute("SELECT key,value FROM kv")
        return {k: json.loads(v) for k,v in cur.fetchall()}

    def close(self):
        self.conn.close()
PY

# ---------- factory.py ----------
cat > "$BASE/factory.py" <<'PY'
from .memory import MemoryStore
from .sqlite import SQLiteStore

def get_store(kind="memory", **kw):
    if kind == "memory":
        return MemoryStore()
    if kind == "sqlite":
        return SQLiteStore(kw.get("path","data.db"))
    raise ValueError("Unsupported store type")
PY

# ---------- __init__.py ----------
cat > "$BASE/__init__.py" <<'PY'
from .factory import get_store
from .memory import MemoryStore
from .sqlite import SQLiteStore
PY

echo "✅ Enterprise Store Installed"
echo "📁 $BASE"
