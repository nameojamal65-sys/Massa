import os, time, threading
_lock = threading.Lock()

def _ensure():
    os.makedirs("logs", exist_ok=True)

def log(msg: str, level: str="INFO", logfile: str="system.log"):
    _ensure()
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} | {level:<5} | {msg}\n"
    with _lock:
        with open(os.path.join("logs", logfile), "a", encoding="utf-8") as f:
            f.write(line)
