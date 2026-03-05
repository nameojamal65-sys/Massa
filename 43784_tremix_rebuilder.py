#!/usr/bin/env python3
import os
import json
import shutil
import subprocess
import zipfile
import time
from pathlib import Path

BASE = Path.home()
SOURCE_ZIP = BASE / "api6.zip"
WORKDIR = BASE / "TremixRebuild"
OLLAMA = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1")

def run(cmd, cwd=None, capture=False):
    return subprocess.run(cmd, cwd=cwd, text=True,
                          capture_output=capture)

def ai(prompt):
    import urllib.request
    payload = json.dumps({
        "model": MODEL,
        "prompt": prompt,
        "stream": False
    }).encode()

    req = urllib.request.Request(
        OLLAMA + "/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"}
    )

    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode())
    return data.get("response", "")

def extract():
    if WORKDIR.exists():
        shutil.rmtree(WORKDIR)
    WORKDIR.mkdir()

    with zipfile.ZipFile(SOURCE_ZIP, 'r') as z:
        z.extractall(WORKDIR)

def analyze_files():
    files = []
    for root, _, fs in os.walk(WORKDIR):
        for f in fs:
            if f.endswith(".py"):
                p = Path(root) / f
                rel = p.relative_to(WORKDIR)
                content = p.read_text(errors="ignore")[:2000]
                files.append({"path": str(rel), "preview": content})
    return files

def rewrite_project(files):
    prompt = f"""
You are a senior Python architect.

Refactor this project into a clean production-ready FastAPI structure.

Return ONLY JSON:
{{
  "files":[{{"path":"...","content":"..."}}]
}}

Project files:
{json.dumps(files)}
"""
    raw = ai(prompt)
    return json.loads(raw)

def apply_changes(data):
    for f in data["files"]:
        path = WORKDIR / f["path"]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f["content"])

def build():
    run(["python3","-m","venv",".venv"], cwd=WORKDIR)
    pip = WORKDIR/".venv/bin/pip"
    pytest = WORKDIR/".venv/bin/pytest"

    run([str(pip),"install","--upgrade","pip"], cwd=WORKDIR)
    run([str(pip),"install","-r","requirements.txt"], cwd=WORKDIR)

    return run([str(pytest)], cwd=WORKDIR, capture=True)

def fix_errors(err):
    prompt = f"""
Fix this project build error:

{err}

Return JSON in same file format.
"""
    raw = ai(prompt)
    return json.loads(raw)

def start():
    uvicorn = WORKDIR/".venv/bin/uvicorn"
    subprocess.Popen([
        str(uvicorn),
        "main:app",
        "--host","127.0.0.1",
        "--port","9100"
    ], cwd=WORKDIR)

def main():
    print("🔍 Extracting...")
    extract()

    print("📊 Analyzing...")
    files = analyze_files()

    print("🧠 Refactoring with AI...")
    data = rewrite_project(files)
    apply_changes(data)

    for attempt in range(3):
        print(f"🔁 Build attempt {attempt+1}")
        result = build()
        if result.returncode == 0:
            print("✅ Build success")
            start()
            print("🚀 Running on http://127.0.0.1:9100")
            return
        else:
            print("❌ Fixing errors...")
            data = fix_errors(result.stderr)
            apply_changes(data)

    print("❌ Failed after retries")

if __name__ == "__main__":
    main()
