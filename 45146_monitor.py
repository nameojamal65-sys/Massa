import os
import platform
from datetime import datetime
import psutil


def snapshot():
    disk = None
    try:
        disk = psutil.disk_usage("/")
    except Exception:
        pass
    mem = None
    try:
        mem = psutil.virtual_memory()
    except Exception:
        pass
    return {
        "ts": datetime.utcnow().isoformat() + "Z",
        "host": platform.node(),
        "platform": platform.platform(),
        "pid": os.getpid(),
        "cpu_percent": psutil.cpu_percent(interval=0.2),
        "mem_percent": mem.percent if mem else None,
        "disk_percent": disk.percent if disk else None,
    }
