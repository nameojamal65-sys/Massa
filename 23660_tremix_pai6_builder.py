#!/usr/bin/env python3
import os
import json
import time
import shutil
import subprocess
from pathlib import Path
import urllib.request

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
MODEL = os.environ.get("OPENAI_MODEL", "gpt-4.1-mini")

if not OPENAI_API_KEY:
    print("❌ OPENAI_API_KEY not found.")
    exit(1)

BASE = Path.home() / "TremixAI"
PROJECTS = BASE / "pai6_projects"
PROJECTS.mkdir(parents=True, exist_ok=True)

def ai(prompt):
    payload = {
        "model": MODEL,
        "input": prompt,
        "temperature": 0.2
    }
    req = urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}"
        },
        method="POST"
    )
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode())
    if "output_text" in data:
        return data["output_text"]
    # fallback
    out = ""
    for o in data.get("output", []):
        for c in o.get("content", []):
            if c.get("type") == "output_text":
                out += c.get("text", "")
    return out.strip()

def run(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)

def build_and_test(path):
    run(["python3","-m","venv",".venv"], cwd=path)
    pip = path/".venv/bin/pip"
    pytest = path/".venv/bin/pytest"

    run([str(pip),"install","-U","pip"], cwd=path)
    if (path/"requirements.txt").exists():
        r = run([str(pip),"install","-r","requirements.txt"], cwd=path)
        if r.returncode != 0:
            return r.returncode, r.stdout + r.stderr

    r = run([str(pytest),"-q"], cwd=path)
    return r.returncode, r.stdout + r.stderr

def main():
    goal = input("🧠 Describe PAI6 goal: ").strip()
    name = "pai6_" + str(int(time.time()))
    path = PROJECTS / name
    path.mkdir()

    system = """
You are an autonomous software architect.
Return STRICT JSON ONLY:
{
 "files":[{"path":"...","content":"..."}],
 "entrypoint":"command to run"
}
Must include:
- FastAPI app
- SQLite persistence
- /api/v1 endpoints
- pytest tests
- requirements.txt
"""

    for attempt in range(6):
        print(f"\n🧠 AI iteration {attempt+1}")
        prompt = system + "\nGoal:\n" + goal
        raw = ai(prompt)

        try:
            data = json.loads(raw)
        except:
            print("❌ Invalid JSON from AI.")
            continue

        # write files
        for f in data.get("files", []):
            target = path / f["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f["content"])

        rc, out = build_and_test(path)
        if rc == 0:
            print("✅ Tests passed.")
            entry = data.get("entrypoint","")
            if entry:
                subprocess.Popen(entry, cwd=path, shell=True)
                print("🚀 Running:", entry)
            print("📁 Project:", path)
            return
        else:
            print("❌ Build failed. Sending errors back to AI...")
            goal += "\nFix errors:\n" + out[:8000]

    print("❌ Failed after retries.")

if __name__ == "__main__":
    main()
