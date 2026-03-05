#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import signal
import time
from datetime import datetime

BASE_DIR = os.path.expanduser("~/Tremix")
PROJECTS_DIR = os.path.join(BASE_DIR, "projects")
REGISTRY_FILE = os.path.join(BASE_DIR, "registry.json")
LOG_FILE = os.path.join(BASE_DIR, "tremix.log")

DEFAULT_HOST = "127.0.0.1"
BASE_PORT = 8000
MAX_PORT = 9000


# ------------------------
# Logging
# ------------------------

def log(msg: str):
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now().isoformat()}] {msg}\n")


def tail_lines(path: str, n: int = 80) -> str:
    if not os.path.exists(path):
        return ""
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    return "".join(lines[-n:])


# ------------------------
# Registry
# ------------------------

def load_registry():
    if not os.path.exists(REGISTRY_FILE):
        return {}
    with open(REGISTRY_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def save_registry(data):
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)


def project_path(name):
    return os.path.join(PROJECTS_DIR, name)


def is_pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except Exception:
        return False


def allocate_port(registry: dict) -> int:
    used = set()
    for svc, info in registry.items():
        p = info.get("port")
        if p:
            try:
                used.add(int(p))
            except Exception:
                pass

    for port in range(BASE_PORT, MAX_PORT + 1):
        if port not in used:
            return port
    raise RuntimeError("No free ports available in range 8000-9000")


# ------------------------
# Project ops
# ------------------------

def create(name):
    os.makedirs(PROJECTS_DIR, exist_ok=True)
    path = project_path(name)
    os.makedirs(path, exist_ok=True)

    main_py = """\
from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def root():
    return {"message": "Sovereign Core Active", "service": "%s"}
""" % name

    with open(os.path.join(path, "main.py"), "w", encoding="utf-8") as f:
        f.write(main_py)

    with open(os.path.join(path, "requirements.txt"), "w", encoding="utf-8") as f:
        f.write("fastapi\nuvicorn\n")

    reg = load_registry()
    reg[name] = {
        "status": "created",
        "created_at": datetime.now().isoformat(),
        "path": path
    }
    save_registry(reg)

    log(f"Created service {name} at {path}")
    print(f"✅ Created {name} at {path}")


def setup(name):
    path = project_path(name)
    venv = os.path.join(path, ".venv")

    if not os.path.exists(os.path.join(venv, "bin", "python")):
        print("🔧 Creating venv...")
        subprocess.run([sys.executable, "-m", "venv", venv], cwd=path, check=True)

    pip = os.path.join(venv, "bin", "pip")
    subprocess.run([pip, "install", "--upgrade", "pip"], cwd=path, check=True)
    subprocess.run([pip, "install", "-r", "requirements.txt"], cwd=path, check=True)

    log(f"Setup venv for {name}")
    print("✅ Setup complete")


def start(name, port=None):
    reg = load_registry()
    info = reg.get(name)

    if not info:
        raise RuntimeError("Service not found. Create it first: create <name>")

    # If running and pid alive, block
    if info.get("status") == "running" and info.get("pid"):
        try:
            pid = int(info["pid"])
            if is_pid_alive(pid):
                print(f"⚠ {name} already running (PID {pid}, port {info.get('port')})")
                return
        except Exception:
            pass

    path = project_path(name)
    uvicorn = os.path.join(path, ".venv", "bin", "uvicorn")

    if not os.path.exists(uvicorn):
        setup(name)

    if port is None:
        port = allocate_port(reg)

    # service log file per service
    svc_log = os.path.join(BASE_DIR, f"{name}.log")

    with open(svc_log, "a", encoding="utf-8") as out:
        proc = subprocess.Popen(
            [
                uvicorn, "main:app",
                "--host", DEFAULT_HOST,
                "--port", str(port),
                "--reload"
            ],
            cwd=path,
            stdout=out,
            stderr=out
        )

    reg[name]["status"] = "running"
    reg[name]["pid"] = proc.pid
    reg[name]["host"] = DEFAULT_HOST
    reg[name]["port"] = int(port)
    reg[name]["svc_log"] = svc_log
    reg[name]["started_at"] = datetime.now().isoformat()
    save_registry(reg)

    log(f"Started {name} pid={proc.pid} port={port}")
    print(f"🚀 {name} started: http://{DEFAULT_HOST}:{port} (PID {proc.pid})")
    print(f"📄 Service log: {svc_log}")


def stop(name):
    reg = load_registry()
    info = reg.get(name)
    if not info:
        print("❌ Not found")
        return

    pid = info.get("pid")
    if not pid:
        print("❌ No PID stored")
        return

    try:
        pid = int(pid)
    except Exception:
        print("❌ Invalid PID")
        return

    if not is_pid_alive(pid):
        reg[name]["status"] = "stopped"
        save_registry(reg)
        print("⚠ Process already dead. Registry updated.")
        return

    # Try TERM then KILL if needed
    try:
        os.kill(pid, signal.SIGTERM)
        time.sleep(0.6)
        if is_pid_alive(pid):
            os.kill(pid, signal.SIGKILL)
        reg[name]["status"] = "stopped"
        save_registry(reg)
        log(f"Stopped {name} pid={pid}")
        print(f"🛑 {name} stopped")
    except Exception as e:
        log(f"Stop error for {name}: {repr(e)}")
        print(f"❌ Stop failed: {e}")


def restart(name):
    stop(name)
    start(name)


def status(name=None):
    reg = load_registry()
    if not reg:
        print("No services registered yet.")
        return

    if name:
        items = {name: reg.get(name)} if reg.get(name) else {}
    else:
        items = reg

    for svc, info in items.items():
        if not info:
            print(f"{svc}: NOT FOUND")
            continue

        pid = info.get("pid")
        alive = False
        if pid:
            try:
                alive = is_pid_alive(int(pid))
            except Exception:
                alive = False

        st = info.get("status")
        host = info.get("host")
        port = info.get("port")
        print(f"- {svc}: status={st} alive={alive} pid={pid} url=http://{host}:{port}")


def logs(name=None, n=80):
    if name:
        reg = load_registry()
        info = reg.get(name, {})
        path = info.get("svc_log") or os.path.join(BASE_DIR, f"{name}.log")
        print(f"📄 {name} logs (last {n} lines): {path}")
        print(tail_lines(path, n))
        return

    print(f"📄 Tremix logs (last {n} lines): {LOG_FILE}")
    print(tail_lines(LOG_FILE, n))


def registry():
    print(json.dumps(load_registry(), indent=4, ensure_ascii=False))


def help_menu():
    print("""
Sovereign Tremix Master (Patch 4)

Commands:
  create <name>
  setup <name>
  start <name> [port]
  stop <name>
  restart <name>
  status [name]
  logs [name] [n]
  registry

Examples:
  python3 tremix_master.py create service1
  python3 tremix_master.py start service1
  python3 tremix_master.py status
  python3 tremix_master.py logs service1 80
""".strip())


def main():
    if len(sys.argv) < 2:
        help_menu()
        return

    cmd = sys.argv[1].lower()

    try:
        if cmd == "create":
            create(sys.argv[2])

        elif cmd == "setup":
            setup(sys.argv[2])

        elif cmd == "start":
            name = sys.argv[2]
            port = int(sys.argv[3]) if len(sys.argv) >= 4 else None
            start(name, port=port)

        elif cmd == "stop":
            stop(sys.argv[2])

        elif cmd == "restart":
            restart(sys.argv[2])

        elif cmd == "status":
            name = sys.argv[2] if len(sys.argv) >= 3 else None
            status(name)

        elif cmd == "logs":
            name = sys.argv[2] if len(sys.argv) >= 3 else None
            n = int(sys.argv[3]) if len(sys.argv) >= 4 else 80
            logs(name, n=n)

        elif cmd == "registry":
            registry()

        else:
            help_menu()

    except Exception as e:
        log(f"ERROR: {repr(e)}")
        print(f"❌ {e}")
        print(f"📄 Tremix log: {LOG_FILE}")


if __name__ == "__main__":
    main()
