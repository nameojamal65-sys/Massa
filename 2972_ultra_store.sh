#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE="sc_ops/store"
mkdir -p "$BASE"

echo "🛡️ Deploying ULTRA Sovereign Military Store Engine..."

cat > "$BASE/core.py" <<'PY'
from abc import ABC, abstractmethod
from typing import Any, Dict
class BaseStore(ABC):
    @abstractmethod
    def get(self, key: str, default: Any = None) -> Any: ...
    @abstractmethod
    def set(self, key: str, value: Any) -> None: ...
    @abstractmethod
    def delete(self, key: str) -> None: ...
    @abstractmethod
    def exists(self, key: str) -> bool: ...
    @abstractmethod
    def all(self) -> Dict[str, Any]: ...
    @abstractmethod
    def flush(self) -> None: ...
PY

cat > "$BASE/memory.py" <<'PY'
from threading import RLock
from .core import BaseStore
class MemoryStore(BaseStore):
    def __init__(self):
        self._d={}
        self._l=RLock()
    def get(self,k,d=None):
        with self._l: return self._d.get(k,d)
    def set(self,k,v):
        with self._l: self._d[k]=v
    def delete(self,k):
        with self._l: self._d.pop(k,None)
    def exists(self,k):
        with self._l: return k in self._d
    def all(self):
        with self._l: return dict(self._d)
    def flush(self):
        with self._l: self._d.clear()
PY

cat > "$BASE/sqlite.py" <<'PY'
import sqlite3,json,os
from .core import BaseStore
class SQLiteStore(BaseStore):
    def __init__(self,path="data/obs.db"):
        os.makedirs(os.path.dirname(path),exist_ok=True)
        self.c=sqlite3.connect(path,check_same_thread=False)
        self.c.execute("CREATE TABLE IF NOT EXISTS obs(k TEXT PRIMARY KEY,v TEXT)")
    def get(self,k,d=None):
        r=self.c.execute("SELECT v FROM obs WHERE k=?",(k,)).fetchone()
        return json.loads(r[0]) if r else d
    def set(self,k,v):
        self.c.execute("INSERT OR REPLACE INTO obs VALUES(?,?)",(k,json.dumps(v)))
        self.c.commit()
    def delete(self,k):
        self.c.execute("DELETE FROM obs WHERE k=?",(k,))
        self.c.commit()
    def exists(self,k):
        return self.c.execute("SELECT 1 FROM obs WHERE k=?",(k,)).fetchone()!=None
    def all(self):
        return {k:json.loads(v) for k,v in self.c.execute("SELECT k,v FROM obs")}
    def flush(self):
        self.c.execute("DELETE FROM obs")
        self.c.commit()
PY

cat > "$BASE/factory.py" <<'PY'
from .memory import MemoryStore
from .sqlite import SQLiteStore
_STORE=None
def get_store():
    global _STORE
    if _STORE is None:
        _STORE=SQLiteStore()
    return _STORE
PY

cat > "$BASE/__init__.py" <<'PY'
from .factory import get_store
PY

echo "✅ Sovereign Store Installed."
