#!/usr/bin/env python3

import os
import json
from datetime import datetime

BASE_DIR = os.path.expanduser("~/Tremix")
MEMORY_FILE = os.path.join(BASE_DIR, "memory.json")


def ensure():
    os.makedirs(BASE_DIR, exist_ok=True)
    if not os.path.exists(MEMORY_FILE):
        with open(MEMORY_FILE, "w") as f:
            json.dump([], f)


def load_memory():
    with open(MEMORY_FILE, "r") as f:
        return json.load(f)


def save_memory(mem):
    with open(MEMORY_FILE, "w") as f:
        json.dump(mem, f, indent=2)


def add_entry(entry_type, content):
    ensure()
    mem = load_memory()
    mem.append({
        "type": entry_type,
        "content": content,
        "timestamp": datetime.now().isoformat()
    })
    save_memory(mem)


def search_memory(keyword):
    ensure()
    mem = load_memory()
    return [m for m in mem if keyword.lower() in json.dumps(m).lower()]


if __name__ == "__main__":
    ensure()
    print("Memory Engine Ready")
