#!/usr/bin/env python3
# ==========================================================
# 👑 PAI6 — Universal Task Engine (Portable)
# ==========================================================
# Runs from ANY directory
# Supports diagnostics, generic tasks, and build checks
# ==========================================================

import os
import sys
import json
import shutil
import subprocess
from datetime import datetime

# ------------------------
# Base Paths (Portable)
# ------------------------
BASE_DIR = os.path.abspath(os.getcwd())
LOG_DIR = os.path.join(BASE_DIR, "task_logs")
os.makedirs(LOG_DIR, exist_ok=True)

# ------------------------
# Logger
# ------------------------
class TaskLogger:
    def __init__(self, log_dir=LOG_DIR):
        self.log_file = os.path.join(log_dir, "task_engine.log")
    def log(self, task, status, message):
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{ts}] [{task}] [{status}] {message}"
        print(line)
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(line + "\n")

# ------------------------
# Diagnostics Engine
# ------------------------
class DiagnosticsEngine:
    def __init__(self):
        self.required_tools = ["python", "node", "npm", "java", "gradle", "git", "zip"]
    def detect_tool(self, tool):
        return shutil.which(tool) is not None
    def full_diagnostic(self):
        return {tool: self.detect_tool(tool) for tool in self.required_tools}
    def self_build_capability(self):
        diag = self.full_diagnostic()
        return {
            "apk_capable": diag.get("java") and diag.get("gradle"),
            "web_capable": diag.get("node") and diag.get("npm"),
            "windows_capable": diag.get("python"),
            "raw": diag
        }

# ------------------------
# Task Executor
# ------------------------
class TaskExecutor:
    def execute(self, command):
        try:
            proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = proc.communicate()
            return proc.returncode == 0, out.decode(), err.decode()
        except Exception as e:
            return False, "", str(e)

# ------------------------
# Universal Task Engine
# ------------------------
class TaskEngine:
    def __init__(self):
        self.logger = TaskLogger()
        self.diagnostics = DiagnosticsEngine()
        self.executor = TaskExecutor()

    def run_task(self, task_name, payload=None):
        payload = payload or {}
        self.logger.log(task_name, "START", json.dumps(payload))
        try:
            if task_name == "diagnostics":
                result = self.diagnostics.full_diagnostic()
            elif task_name == "self_build_check":
                result = self.diagnostics.self_build_capability()
            elif task_name == "exec":
                cmd = payload.get("command")
                if not cmd: raise ValueError("Missing command")
                ok, out, err = self.executor.execute(cmd)
                result = {"success": ok, "stdout": out, "stderr": err}
            elif task_name == "build_apk":
                result = self._virtual_apk_builder()
            else:
                raise ValueError(f"Unknown Task: {task_name}")
            self.logger.log(task_name, "SUCCESS", json.dumps(result, indent=2))
            return {"status": "success", "result": result}
        except Exception as e:
            self.logger.log(task_name, "ERROR", str(e))
            return {"status": "error", "message": str(e)}

    def _virtual_apk_builder(self):
        diag = self.diagnostics.self_build_capability()
        if not diag["apk_capable"]:
            return {"ready": False, "reason": "Missing Android build dependencies", "diagnostics": diag}
        return {"ready": True, "message": "PAI6 Core can build APK autonomously", "next_step": "Attach Android build pipeline"}

# ------------------------
# CLI / Manual Test
# ------------------------
if __name__ == "__main__":
    engine = TaskEngine()
    print("\n👑 PAI6 — Universal Task Engine (Portable)\n")
    print("1️⃣ Diagnostics:")
    print(json.dumps(engine.run_task("diagnostics"), indent=2))
    print("\n2️⃣ Self Build Capability:")
    print(json.dumps(engine.run_task("self_build_check"), indent=2))
    print("\n3️⃣ Generic Task Test:")
    print(json.dumps(engine.run_task("exec", {"command": "echo PAI6 CORE ONLINE"}), indent=2))
