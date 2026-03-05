import os
import ast
import requests
import math
import threading
import queue

SYSTEM_PATH = "/home/user/sovereign_system_fixed/sovereign_system"
CAPABILITIES = ["Data Collection", "Data Processing", "Analytics", "Dashboard", "AI Engine"]

# --- File Analysis ---
def analyze_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            tree = ast.parse(f.read())
        functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
        classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
        return {"functions": functions, "classes": classes}
    except:
        return {"error": "Could not parse"}

def detect_capabilities(file_name):
    caps = []
    name = file_name.lower()
    if "collect" in name or "collector" in name:
        caps.append("Data Collection")
    if "process" in name or "worker" in name or "prepare" in name:
        caps.append("Data Processing")
    if "analytics" in name or "report" in name:
        caps.append("Analytics")
    if "dashboard" in name or "view" in name or "blueprint" in name:
        caps.append("Dashboard")
    if "ai" in name or "engine" in name or "optimizer" in name or "organizer" in name:
        caps.append("AI Engine")
    if not caps:
        caps.append("Unknown")
    return caps

# --- System Structure ---
system_structure = {}
for root, dirs, files in os.walk(SYSTEM_PATH):
    for file in files:
        if file.endswith(".py"):
            rel_path = os.path.relpath(os.path.join(root, file), SYSTEM_PATH)
            system_structure[rel_path] = {
                "capabilities": detect_capabilities(file),
                "analysis": analyze_file(os.path.join(root, file))
            }

# --- Internet Data Fetching ---
def fetch_url(url):
    try:
        r = requests.get(url, timeout=5)
        return r.text
    except:
        return ""

# --- Heavy Computation Example ---
def heavy_math_task(n):
    result = sum(math.factorial(i) for i in range(1, n+1))
    return result

# --- Multi-threaded Task Runner ---
task_queue = queue.Queue()

def worker():
    while True:
        task = task_queue.get()
        if task is None:
            break
        func, args = task
        print(f"Task result: {func(*args)}")
        task_queue.task_done()

threads = []
for _ in range(4):
    t = threading.Thread(target=worker)
    t.start()
    threads.append(t)

# --- CLI ---
def search_by_capability():
    while True:
        print("\nAvailable Capabilities:")
        for i, cap in enumerate(CAPABILITIES + ["Unknown"], 1):
            print(f"{i}. {cap}")
        choice = input("\nEnter capability number (or 'q' to quit): ").strip()
        if choice.lower() == "q":
            break
        if not choice.isdigit() or not (1 <= int(choice) <= len(CAPABILITIES)+1):
            print("Invalid choice, try again.")
            continue
        cap = (CAPABILITIES + ["Unknown"])[int(choice)-1]
        files = [f for f, v in system_structure.items() if cap in v["capabilities"]]
        print(f"\nFiles with capability '{cap}': ({len(files)})")
        for f in files:
            print(f" • {f}")

# --- Auto-run heavy tasks example ---
task_queue.put((heavy_math_task, (5000,)))

# --- Wait for tasks to finish before exit ---
def shutdown_workers():
    for _ in threads:
        task_queue.put(None)
    for t in threads:
        t.join()

# --- Main ---
if __name__ == "__main__":
    print("✅ Sovereign AI System Ready!")
    search_by_capability()
    task_queue.join()
    shutdown_workers()

