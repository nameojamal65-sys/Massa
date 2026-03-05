#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path
import urllib.request

OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
MODEL = os.environ.get("OPENAI_MODEL", "gpt-4.1-mini")

if not OPENAI_API_KEY:
    print("❌ OPENAI_API_KEY not set.")
    exit(1)

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

    text = ""
    for o in data.get("output", []):
        for c in o.get("content", []):
            if c.get("type") == "output_text":
                text += c.get("text", "")
    return text.strip()

def scan_project(path):
    files = []
    for root, dirs, filenames in os.walk(path):
        if ".venv" in root:
            continue
        for f in filenames:
            if f.endswith(".py"):
                p = Path(root)/f
                try:
                    files.append({
                        "path": str(p.relative_to(path)),
                        "content": p.read_text()[:8000]
                    })
                except:
                    pass
    return files[:20]

def apply_patch(path, patch):
    for f in patch.get("files", []):
        target = path / f["path"]
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(f["content"])

def run_tests(path):
    pytest = path/".venv/bin/pytest"
    if pytest.exists():
        r = subprocess.run([str(pytest), "-q"], cwd=path, capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr
    return 0, ""

def main():
    project_path = input("📁 Project path: ").strip()
    path = Path(project_path).expanduser()

    if not path.exists():
        print("❌ Path not found.")
        return

    instruction = input("🧠 What to generate/modify? ").strip()

    manifest = scan_project(path)

    system = """
You are an advanced code generator.
Return STRICT JSON ONLY:
{
 "files":[{"path":"relative/path.py","content":"..."}]
}
Modify existing files if needed.
Ensure pytest tests pass.
"""

    prompt = system + "\nProject Files:\n" + json.dumps(manifest) + "\nInstruction:\n" + instruction

    raw = ai(prompt)

    try:
        patch = json.loads(raw)
    except:
        print("❌ AI returned invalid JSON.")
        return

    apply_patch(path, patch)

    rc, out = run_tests(path)
    if rc == 0:
        print("✅ Code generated and tests pass.")
    else:
        print("⚠️ Tests failed:\n", out)

    print("✨ Done.")

if __name__ == "__main__":
    main()
