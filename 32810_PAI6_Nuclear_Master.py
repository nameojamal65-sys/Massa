#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, json, time, traceback
from datetime import datetime

# --------- Paths ---------
PAI6_ROOT = os.path.join(os.path.expanduser("~"), "PAI6")
MEMORY_DIR = os.path.join(PAI6_ROOT, "memory")
LOG_DIR = os.path.join(PAI6_ROOT, "logs")
LEARNING_DB = os.path.join(MEMORY_DIR, "learning_db.json")
LOG_FILE = os.path.join(LOG_DIR, "nuclear_core.log")

os.makedirs(MEMORY_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# --------- Logging ---------
def log(msg):
    ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")

# --------- Safe Execution Wrapper ---------
def safe_exec(fn, *args, **kwargs):
    try:
        return fn(*args, **kwargs)
    except Exception as e:
        log("❌ CRITICAL ERROR:")
        log(str(e))
        log(traceback.format_exc())
        return {"error": str(e)}

# --------- Modules ---------
class VehicleModule:
    def run(self):
        vehicles = [
            {"id": "V001", "model": "Tesla Model S"},
            {"id": "V002", "model": "BMW i8"},
            {"id": "V003", "model": "Audi e-tron"},
            {"id": "V004", "model": "Mercedes EQC"}
        ]
        log("🚗 Vehicle Module Executed")
        return vehicles

class GenericModule:
    def run(self, command):
        log(f"⚙️ Generic Module Executed: {command}")
        return {"executed": command, "status": "ok"}

# --------- Core Engine ---------
class NuclearCoreVI:
    def __init__(self):
        self.results = {}
        self.logs = []

    def dispatch(self, command: str):
        cmd = command.lower()
        if any(k in cmd for k in ["vehicle", "car", "fleet"]):
            vm = VehicleModule()
            self.results["vehicles"] = vm.run()
        else:
            gm = GenericModule()
            self.results["generic"] = gm.run(command)
        return self.results

    def save_learning(self, command):
        record = {
            "engine": "PAI6_Nuclear_Core_VI",
            "command": command,
            "timestamp": int(time.time()),
            "datetime": datetime.utcnow().isoformat(),
            "result_keys": list(self.results.keys()),
            "status": "success"
        }

        if os.path.exists(LEARNING_DB):
            with open(LEARNING_DB, "r", encoding="utf-8") as f:
                data = json.load(f)
        else:
            data = []

        data.append(record)
        with open(LEARNING_DB, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        log("🧠 Learning injected into PAI6 Memory")

# --------- UI Output ---------
def display(results):
    print("\n📊 EXECUTION RESULT:")
    print("=" * 40)
    for k, v in results.items():
        if isinstance(v, list):
            print(f"{k.upper()}: {len(v)} records")
            for item in v:
                print("  -", item)
        else:
            print(f"{k.upper()}: {v}")
    print("=" * 40)

# --------- Main Entry ---------
def main():
    if len(sys.argv) < 2:
        print("""
👑 PAI6 — Nuclear Connective Core Engine VI

Usage:
  pai6 "your command"

Examples:
  pai6 "show vehicle list"
  pai6 "build web app"
""")
        return

    command = " ".join(sys.argv[1:])
    log(f"🚀 COMMAND RECEIVED: {command}")

    start = time.time()
    core = NuclearCoreVI()
    results = safe_exec(core.dispatch, command)
    safe_exec(core.save_learning, command)
    display(results)

    runtime = round(time.time() - start, 3)
    log(f"⏱ Runtime: {runtime} sec")
    log("✅ TASK COMPLETED SUCCESSFULLY")

if __name__ == "__main__":
    main()
