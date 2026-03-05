#!/usr/bin/env python3
import os
import subprocess
import json
import time
import shutil

PROJECT_ROOT = os.path.expanduser("~/Tremix/builds")
AI_BACKEND = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL = os.environ.get("OLLAMA_MODEL", "llama3.1")

def ai_generate(prompt):
    import urllib.request
    payload = json.dumps({
        "model": MODEL,
        "prompt": prompt,
        "stream": False
    }).encode()
    req = urllib.request.Request(
        AI_BACKEND + "/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
    return data.get("response", "")

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

def build_project(name, idea):
    path = os.path.join(PROJECT_ROOT, name)
    if os.path.exists(path):
        shutil.rmtree(path)
    os.makedirs(path)

    prompt = f"""
Create a production-ready Python FastAPI project.
Project idea: {idea}

Return ONLY JSON:
{{
  "files": [
    {{"path":"main.py","content":"..."}},
    {{"path":"requirements.txt","content":"..."}},
    {{"path":"test_app.py","content":"..."}}
  ]
}}
"""

    raw = ai_generate(prompt)
    data = json.loads(raw)

    for file in data["files"]:
        write_file(os.path.join(path, file["path"]), file["content"])

    return path

def install_and_test(path):
    subprocess.run(["python3","-m","venv",".venv"], cwd=path)
    pip = os.path.join(path,".venv/bin/pip")
    pytest = os.path.join(path,".venv/bin/pytest")

    subprocess.run([pip,"install","--upgrade","pip"], cwd=path)
    subprocess.run([pip,"install","-r","requirements.txt"], cwd=path)

    result = subprocess.run([pytest], cwd=path, capture_output=True, text=True)
    return result

def fix_errors(path, error):
    prompt = f"""
Fix the following project errors:

{error}

Return ONLY JSON in same format.
"""
    raw = ai_generate(prompt)
    data = json.loads(raw)
    for file in data["files"]:
        write_file(os.path.join(path, file["path"]), file["content"])

def run_server(path):
    uvicorn = os.path.join(path,".venv/bin/uvicorn")
    subprocess.Popen([uvicorn,"main:app","--host","127.0.0.1","--port","9000"], cwd=path)

def main():
    idea = input("💡 Enter project idea: ")
    name = "project_" + str(int(time.time()))

    path = build_project(name, idea)

    for attempt in range(3):
        print(f"🔁 Build attempt {attempt+1}")
        result = install_and_test(path)

        if result.returncode == 0:
            print("✅ Tests passed")
            run_server(path)
            print("🚀 Running on http://127.0.0.1:9000")
            return
        else:
            print("❌ Errors detected. Fixing...")
            fix_errors(path, result.stderr)

    print("❌ Failed after retries")

if __name__ == "__main__":
    main()
