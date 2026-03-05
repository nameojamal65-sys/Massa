import sqlite3
from contextlib import contextmanager
from typing import Iterator
from app.config import db_path

def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(db_path(), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db(conn: sqlite3.Connection) -> None:
    conn.execute("""
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sku TEXT NOT NULL UNIQUE,
      quantity INTEGER NOT NULL CHECK(quantity >= 0)
    );
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_items_name ON items(name);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_items_sku ON items(sku);")
    conn.commit()

@contextmanager
def get_conn() -> Iterator[sqlite3.Connection]:
    conn = connect()
    try:
        init_db(conn)
        yield conn
    finally:
        conn.close()
