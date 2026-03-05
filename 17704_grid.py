import os, json, time, sqlite3, threading, socket

DATA="data/grid.db"
os.makedirs("data",exist_ok=True)

class SovereignGrid:
    def __init__(self,path=DATA):
        self.db=sqlite3.connect(path,check_same_thread=False)
        self.db.execute("CREATE TABLE IF NOT EXISTS log(ts REAL,key TEXT,val TEXT)")
        self.lock=threading.RLock()

    def set(self,key,val):
        with self.lock:
            self.db.execute("INSERT INTO log VALUES(?,?,?)",(time.time(),key,json.dumps(val)))
            self.db.commit()

    def get(self,key,default=None):
        r=self.db.execute("SELECT val FROM log WHERE key=? ORDER BY ts DESC LIMIT 1",(key,)).fetchone()
        return json.loads(r[0]) if r else default

    def snapshot(self):
        with self.lock:
            snap={k:self.get(k) for k, in self.db.execute("SELECT DISTINCT key FROM log")}
            open("data/snapshot.json","w").write(json.dumps(snap,indent=2))
            return snap

    def health(self):
        return {
            "hostname": socket.gethostname(),
            "time": time.ctime(),
            "entries": self.db.execute("SELECT COUNT(*) FROM log").fetchone()[0]
        }

GRID = SovereignGrid()
