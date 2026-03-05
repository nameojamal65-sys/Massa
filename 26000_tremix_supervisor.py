#!/usr/bin/env python3

import os
import json
import time
import subprocess
import signal
from datetime import datetime

BASE_DIR = os.path.expanduser("~/Tremix")
REGISTRY_FILE = os.path.join(BASE_DIR, "registry.json")
LOG_FILE = os.path.join(BASE_DIR, "supervisor.log")

CHECK_INTERVAL = 5


def log(msg):
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.now().isoformat()}] {msg}\n")


def load_registry():
    if not os.path.exists(REGISTRY_FILE):
        return {}
    with open(REGISTRY_FILE, "r") as f:
        return json.load(f)


def save_registry(data):
    with open(REGISTRY_FILE, "w") as f:
        json.dump(data, f, indent=4)


def is_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except:
        return False


def restart_service(name, info):
    path = info.get("path")
    port = info.get("port")

    if not path or not port:
        return

    uvicorn = os.path.join(path, ".venv", "bin", "uvicorn")
    if not os.path.exists(uvicorn):
        return

    proc = subprocess.Popen(
        [uvicorn, "main:app", "--host", "127.0.0.1", "--port", str(port)],
        cwd=path
    )

    info["pid"] = proc.pid
    info["status"] = "running"
    info["restarts"] = info.get("restarts", 0) + 1
    log(f"Auto-restarted {name} (PID {proc.pid})")


def supervisor_loop():
    log("Supervisor started")
    while True:
        registry = load_registry()

        for name, info in registry.items():
            if info.get("status") != "running":
                continue

            pid = info.get("pid")
            if not pid or not is_alive(pid):
                log(f"{name} crashed. Restarting...")
                restart_service(name, info)

        save_registry(registry)
        time.sleep(CHECK_INTERVAL)


if __name__ == "__main__":
    supervisor_loop()
