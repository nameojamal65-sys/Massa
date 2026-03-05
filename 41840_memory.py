import sqlite3
from pathlib import Path
DB = Path(__file__).parent.parent / "data/memory.db"

def init():
DB.parent.mkdir(exist_ok=True)
con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS memory (key TEXT, value TEXT)")
con.commit(); con.close()

def store(k,v):
con = sqlite3.connect(DB)
cur = con.cursor()
cur.execute("INSERT INTO memory VALUES (?,?)",(k,v))
con.commit(); con.close()