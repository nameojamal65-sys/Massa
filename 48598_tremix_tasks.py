#!/usr/bin/env python3
import os, json, time
from datetime import datetime

BASE_DIR = os.path.expanduser("~/Tremix")
TASK_FILE = os.path.join(BASE_DIR, "tasks.json")
OUTBOX_DIR = os.path.join(BASE_DIR, "outbox")
MEMORY_FILE = os.path.join(BASE_DIR, "memory.json")

CHECK_INTERVAL = 3

def ensure():
    os.makedirs(BASE_DIR, exist_ok=True)
    os.makedirs(OUTBOX_DIR, exist_ok=True)
    if not os.path.exists(TASK_FILE):
        with open(TASK_FILE, "w", encoding="utf-8") as f:
            json.dump([], f, indent=2, ensure_ascii=False)
    if not os.path.exists(MEMORY_FILE):
        with open(MEMORY_FILE, "w", encoding="utf-8") as f:
            json.dump([], f, indent=2, ensure_ascii=False)

def load_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default

def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def add_memory(entry_type: str, content):
    mem = load_json(MEMORY_FILE, [])
    mem.append({
        "type": entry_type,
        "content": content,
        "ts": datetime.now().isoformat()
    })
    save_json(MEMORY_FILE, mem)

def doctor_pipeline(task):
    text = (task.get("data") or "").strip()

    # Heuristic doctors (works offline on Termux)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    issues = [ln for ln in lines if any(k in ln.lower() for k in ["traceback", "error", "exception", "failed"])]
    actions = [ln for ln in lines if any(k in ln.lower() for k in ["todo", "fixme", "fix", "urgent", "مطلوب", "لازم", "ضروري"])]

    result = {
        "task_id": task.get("id"),
        "summary": (text[:300] + ("..." if len(text) > 300 else "")),
        "key_points": lines[:10],
        "issues": issues[:10],
        "actions": actions[:10],
        "processed_at": datetime.now().isoformat()
    }

    out_path = os.path.join(OUTBOX_DIR, f"task_{task.get('id')}.json")
    save_json(out_path, result)

    # ✅ Memory link
    add_memory("task_result", result)
    return result

def worker_loop():
    print("✅ Tremix Task Worker ONLINE")
    print(f"- tasks:   {TASK_FILE}")
    print(f"- outbox:  {OUTBOX_DIR}")
    print(f"- memory:  {MEMORY_FILE}")
    print("----")

    while True:
        tasks = load_json(TASK_FILE, [])
        changed = False

        for task in tasks:
            if task.get("status") == "pending":
                task["status"] = "running"
                task["started_at"] = datetime.now().isoformat()
                save_json(TASK_FILE, tasks)

                try:
                    doctor_pipeline(task)
                    task["status"] = "done"
                    task["done_at"] = datetime.now().isoformat()
                except Exception as e:
                    task["status"] = "failed"
                    task["error"] = str(e)
                    task["failed_at"] = datetime.now().isoformat()

                changed = True

        if changed:
            save_json(TASK_FILE, tasks)

        time.sleep(CHECK_INTERVAL)

def add_task(data: str):
    tasks = load_json(TASK_FILE, [])
    next_id = 1
    if tasks:
        try:
            next_id = max(int(t.get("id", 0)) for t in tasks) + 1
        except Exception:
            next_id = len(tasks) + 1

    task = {
        "id": next_id,
        "status": "pending",
        "data": data,
        "created_at": datetime.now().isoformat()
    }
    tasks.append(task)
    save_json(TASK_FILE, tasks)
    print(f"✅ Task added: id={next_id}")

if __name__ == "__main__":
    ensure()

    # Usage:
    #   python3 ~/tremix_tasks.py worker
    #   python3 ~/tremix_tasks.py add "text..."
    import sys
    if len(sys.argv) >= 2 and sys.argv[1].lower() == "add":
        add_task(" ".join(sys.argv[2:]).strip())
    else:
        worker_loop()
