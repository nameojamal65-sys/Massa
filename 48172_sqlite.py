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
