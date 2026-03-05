#!/usr/bin/env python3
import os
import sys
import json
import time
import shutil
import zipfile
import subprocess
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
import urllib.request
import urllib.error

# ----------------------------
# Settings
# ----------------------------
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "").strip()
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4.1-mini").strip()

BASE_DIR = Path.home() / "TremixAI"
RUNS_DIR = BASE_DIR / "runs"
MAX_ITERS_DEFAULT = 6

# Hard caps to avoid sending huge payloads to the model
MAX_FILE_BYTES_TO_SEND = 20_000
MAX_FILES_TO_SEND = 40

# ----------------------------
# Utility
# ----------------------------
def die(msg: str, code: int = 1):
    print(f"❌ {msg}")
    sys.exit(code)

def sh(cmd: List[str], cwd: Optional[Path] = None, capture: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=str(cwd) if cwd else None, text=True, capture_output=capture)

def ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)

def is_probably_text(path: Path) -> bool:
    if path.suffix.lower() in {".py",".md",".txt",".json",".yaml",".yml",".toml",".ini",".cfg",".sh",".env",".csv"}:
        return True
    try:
        b = path.read_bytes()[:4096]
        return b"\x00" not in b
    except Exception:
        return False

def read_text_capped(path: Path) -> str:
    try:
        b = path.read_bytes()
        if len(b) > MAX_FILE_BYTES_TO_SEND:
            b = b[:MAX_FILE_BYTES_TO_SEND]
        return b.decode("utf-8", errors="ignore")
    except Exception:
        return ""

def scan_repo(repo: Path) -> List[Dict[str, Any]]:
    """
    Return a compact manifest of files for the model:
    - path
    - size
    - preview (capped)
    """
    items: List[Tuple[Path, int]] = []
    for root, dirs, files in os.walk(repo):
        # skip venv and caches
        dirs[:] = [d for d in dirs if d not in {".venv","venv","__pycache__",".git",".pytest_cache",".ruff_cache",".mypy_cache","node_modules","dist","build"}]
        for f in files:
            p = Path(root) / f
            try:
                sz = p.stat().st_size
            except Exception:
                continue
            items.append((p, sz))

    # prioritize likely relevant files
    def score(p: Path, sz: int) -> int:
        s = 0
        name = p.name.lower()
        if name in {"main.py","app.py","server.py","wsgi.py","asgi.py","requirements.txt","pyproject.toml","dockerfile","compose.yml","docker-compose.yml"}:
            s += 200
        if "test" in name or "tests" in str(p).lower():
            s += 120
        if p.suffix.lower() == ".py":
            s += 80
        if p.suffix.lower() in {".md",".txt"}:
            s += 20
        # smaller files are easier to send
        s += max(0, 50 - (sz // 2000))
        return s

    items.sort(key=lambda x: score(x[0], x[1]), reverse=True)

    manifest: List[Dict[str, Any]] = []
    for p, sz in items[:MAX_FILES_TO_SEND]:
        rel = str(p.relative_to(repo))
        entry = {"path": rel, "bytes": sz}
        if is_probably_text(p):
            entry["preview"] = read_text_capped(p)
        manifest.append(entry)
    return manifest

def apply_patch(repo: Path, patch: Dict[str, Any]):
    """
    patch format:
    {
      "files": [
        {"path":"relative/path", "content":"..."},
        {"path":"relative/path", "delete": true}
      ]
    }
    """
    files = patch.get("files")
    if not isinstance(files, list):
        die("AI patch missing 'files' list (invalid JSON).")
    for f in files:
        if not isinstance(f, dict) or "path" not in f:
            continue
        rel = f["path"].lstrip("/").replace("\\", "/")
        target = repo / rel
        if f.get("delete") is True:
            if target.exists():
                target.unlink()
            continue
        content = f.get("content", "")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

def openai_responses_json(system: str, user: str) -> Dict[str, Any]:
    if not OPENAI_API_KEY:
        die("OPENAI_API_KEY not set in environment.")
    url = "https://api.openai.com/v1/responses"
    payload = {
        "model": OPENAI_MODEL,
        "input": [
            {"role": "system", "content": [{"type":"text","text": system}]},
            {"role": "user", "content": [{"type":"text","text": user}]}
        ],
        "temperature": 0.2
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}"
        },
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8", errors="ignore")
        return json.loads(raw)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore") if hasattr(e, "read") else ""
        die(f"OpenAI HTTPError: {e.code} {e.reason}\n{body}")
    except Exception as e:
        die(f"OpenAI request failed: {e}")

def extract_output_text(resp: Dict[str, Any]) -> str:
    # Responses API provides output_text in some responses; fallback to parse output array
    if isinstance(resp, dict) and resp.get("output_text"):
        return resp["output_text"]
    out = resp.get("output", [])
    chunks: List[str] = []
    for item in out:
        content = item.get("content", [])
        for c in content:
            if c.get("type") == "output_text":
                chunks.append(c.get("text", ""))
    return "\n".join(chunks).strip()

# ----------------------------
# Agent
# ----------------------------
SYSTEM_PROMPT = """You are Tremix Online AI Dev Agent.
You will refactor and productize a codebase into a clean, runnable, testable product.

Hard rules:
- ALWAYS respond with STRICT JSON ONLY (no markdown, no commentary).
- Output schema:
  {
    "intent": "patch",
    "summary": "one-line summary",
    "files": [
      {"path":"relative/path", "content":"..."},
      {"path":"relative/path", "delete": true}
    ],
    "commands": ["optional shell commands to run (safe)"],
    "entrypoint": "how to run (e.g., uvicorn app.main:app --host 127.0.0.1 --port 9000)"
  }
- Keep changes minimal but correct.
- Ensure `pytest -q` passes.
- Ensure there is a clear run command (FastAPI preferred if web API).
- Prefer SQLite for persistence if applicable.
- If requirements are unclear, create/adjust requirements.txt.
- If there is no test suite, add a minimal one with fastapi TestClient.
"""

def build_and_test(repo: Path) -> Tuple[int, str]:
    # create venv
    sh([sys.executable, "-m", "venv", ".venv"], cwd=repo, capture=False)
    pip = repo / ".venv" / "bin" / "pip"
    pytest = repo / ".venv" / "bin" / "pytest"

    # upgrade pip
    sh([str(pip), "install", "-U", "pip"], cwd=repo, capture=True)

    # install deps
    if (repo / "requirements.txt").exists():
        r = sh([str(pip), "install", "-r", "requirements.txt"], cwd=repo, capture=True)
        if r.returncode != 0:
            return r.returncode, "pip install failed:\n" + (r.stdout or "") + "\n" + (r.stderr or "")
    else:
        # Try to run without deps install
        pass

    # run tests (if tests exist, else create failure message so agent adds tests)
    r = sh([str(pytest), "-q"], cwd=repo, capture=True)
    return r.returncode, (r.stdout or "") + "\n" + (r.stderr or "")

def run_entrypoint(repo: Path, entrypoint: str) -> Tuple[bool, str]:
    """
    Start service in background using nohup.
    """
    if not entrypoint or not isinstance(entrypoint, str):
        return False, "No entrypoint provided."
    # Only allow a safe subset: uvicorn/python commands
    if ("rm " in entrypoint) or ("sudo" in entrypoint) or ("chmod" in entrypoint) or ("dd " in entrypoint):
        return False, "Unsafe entrypoint rejected."
    log = repo / "run.log"
    cmd = f"nohup {entrypoint} > {log} 2>&1 &"
    r = sh(["bash", "-lc", cmd], cwd=repo, capture=True)
    if r.returncode != 0:
        return False, (r.stdout or "") + "\n" + (r.stderr or "")
    return True, f"Started. Log: {log}"

def find_zip_candidate(zip_path: Optional[str]) -> Path:
    if zip_path:
        p = Path(zip_path).expanduser()
        if not p.exists():
            die(f"ZIP not found: {p}")
        return p
    # default heuristics: pick source_code_*.zip if exists, else any zip in HOME
    home = Path.home()
    cand = sorted(home.glob("source_code_*.zip"), key=lambda x: x.stat().st_mtime, reverse=True)
    if cand:
        return cand[0]
    cand2 = sorted(home.glob("*.zip"), key=lambda x: x.stat().st_mtime, reverse=True)
    if cand2:
        return cand2[0]
    die("No ZIP provided and none found in HOME.")

def extract_zip(zip_file: Path, dest: Path):
    ensure_dir(dest)
    with zipfile.ZipFile(zip_file, "r") as z:
        z.extractall(dest)

def locate_project_root(dest: Path) -> Path:
    """
    Heuristic: if extracted contains a single top folder, use it; else use dest.
    """
    entries = [p for p in dest.iterdir()]
    if len(entries) == 1 and entries[0].is_dir():
        return entries[0]
    return dest

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Tremix Online AI Dev Agent (OpenAI)")
    parser.add_argument("--goal", required=True, help="What product to produce / desired outcome")
    parser.add_argument("--zip", default="", help="Path to existing code zip to productize")
    parser.add_argument("--iters", type=int, default=MAX_ITERS_DEFAULT, help="Max AI fix iterations")
    parser.add_argument("--port", type=int, default=9000, help="Preferred port for web services")
    args = parser.parse_args()

    ensure_dir(RUNS_DIR)
    run_id = time.strftime("%Y%m%d_%H%M%S")
    run_dir = RUNS_DIR / f"run_{run_id}"
    ensure_dir(run_dir)

    # Prepare workspace
    if args.zip:
        zip_file = find_zip_candidate(args.zip)
        print(f"📦 Using ZIP: {zip_file}")
    else:
        zip_file = find_zip_candidate(None)
        print(f"📦 Auto-selected ZIP: {zip_file}")

    extract_dir = run_dir / "src"
    extract_zip(zip_file, extract_dir)
    repo = locate_project_root(extract_dir)

    print(f"📁 Workspace: {repo}")

    # First manifest
    manifest = scan_repo(repo)

    # Iteration loop
    last_error = ""
    entrypoint = ""
    for i in range(1, args.iters + 1):
        print(f"\n🧠 AI iteration {i}/{args.iters}")

        user_payload = {
            "goal": args.goal,
            "preferred_port": args.port,
            "repo_root": str(repo),
            "manifest": manifest,
            "last_error": last_error[:12000],
            "requirements": "Ensure runnable product + tests pass (`pytest -q`)."
        }

        resp = openai_responses_json(SYSTEM_PROMPT, json.dumps(user_payload, ensure_ascii=False))
        text = extract_output_text(resp)

        try:
            patch = json.loads(text)
        except Exception:
            # Save raw for debugging
            (run_dir / f"ai_raw_{i}.txt").write_text(text, encoding="utf-8")
            die("AI did not return valid JSON. Saved raw output for inspection.")

        if patch.get("intent") != "patch":
            die("AI response JSON missing intent='patch'.")

        summary = patch.get("summary", "")
        print(f"🧩 Patch summary: {summary}")

        # Apply patch
        apply_patch(repo, patch)

        # Optional safe commands
        cmds = patch.get("commands", [])
        if isinstance(cmds, list) and cmds:
            for c in cmds[:6]:
                if not isinstance(c, str):
                    continue
                # reject dangerous commands
                bad = ["rm -rf", "mkfs", "dd ", "sudo", "chmod 777", ":(){", "shutdown", "reboot"]
                if any(b in c for b in bad):
                    print(f"⚠️ Skipping unsafe command: {c}")
                    continue
                print(f"🔧 Running: {c}")
                sh(["bash", "-lc", c], cwd=repo, capture=False)

        # Build & test
        rc, out = build_and_test(repo)
        if rc == 0:
            print("✅ Tests passed.")
            entrypoint = patch.get("entrypoint", "") or entrypoint
            if entrypoint:
                ok, msg = run_entrypoint(repo, entrypoint)
                if ok:
                    print(f"🚀 {msg}")
                    print(f"📌 Entrypoint: {entrypoint}")
                else:
                    print(f"⚠️ Could not start service: {msg}")
            else:
                print("ℹ️ No entrypoint provided. Tests passed though.")
            # Final report
            report = {
                "ok": True,
                "run_dir": str(run_dir),
                "repo": str(repo),
                "entrypoint": entrypoint,
                "summary": summary,
            }
            (run_dir / "result.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
            print(f"🧾 Report: {run_dir / 'result.json'}")
            return

        # Failure: feed back error and rescan
        last_error = out
        (run_dir / f"test_fail_{i}.log").write_text(out, encoding="utf-8")
        print("❌ Tests failed. Error saved.")
        manifest = scan_repo(repo)

    # If exhausted
    report = {
        "ok": False,
        "run_dir": str(run_dir),
        "repo": str(repo),
        "last_error": last_error[:12000],
    }
    (run_dir / "result.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    die(f"Failed after {args.iters} iterations. See: {run_dir / 'result.json'}")

if __name__ == "__main__":
    main()
