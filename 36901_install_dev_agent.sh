#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJECT_DIR="/data/data/com.termux/files/home/sovereign_core"
cd "$PROJECT_DIR"

if [ ! -d ".venv" ]; then
  echo "❌ .venv not found in $PROJECT_DIR"
  echo "   Create venv first then rerun."
  exit 1
fi

# shellcheck disable=SC1091
source .venv/bin/activate

echo "✅ Installing deps..."
pip -q install -U openai rich >/dev/null

echo "✅ Creating dev_agent package..."
mkdir -p dev_agent

cat > dev_agent/__init__.py <<'PY'
__all__ = ["cli"]
PY

cat > dev_agent/scanner.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

DEFAULT_GLOBS = (
    "app/**/*.py",
    "app/**/*.html",
    "app/**/*.toml",
    "app/**/*.yml",
    "app/**/*.yaml",
    "requirements.txt",
    "pyproject.toml",
    "alembic.ini",
)

EXCLUDE_PARTS = ("__pycache__", ".venv", ".git", ".mypy_cache", ".pytest_cache", ".ai_audit_tmp", ".agent_tmp")

@dataclass
class FileDoc:
    path: str
    text: str

def _is_excluded(p: Path) -> bool:
    s = str(p)
    return any(part in s for part in EXCLUDE_PARTS)

def list_files(root: Path, globs: Iterable[str] = DEFAULT_GLOBS) -> list[Path]:
    files: list[Path] = []
    for g in globs:
        files.extend(root.glob(g))
    out = []
    for p in sorted(set(files)):
        if p.is_file() and not _is_excluded(p):
            out.append(p)
    return out

def read_files(root: Path, paths: list[Path]) -> list[FileDoc]:
    docs: list[FileDoc] = []
    for p in paths:
        try:
            txt = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        docs.append(FileDoc(path=str(p), text=txt))
    return docs
PY

cat > dev_agent/patcher.py <<'PY'
from __future__ import annotations

import difflib
from dataclasses import dataclass
from pathlib import Path
from datetime import datetime

@dataclass
class Patch:
    path: str
    before: str
    after: str
    rationale: str = ""

def unified_diff(path: str, before: str, after: str) -> str:
    a = before.splitlines(keepends=True)
    b = after.splitlines(keepends=True)
    return "".join(difflib.unified_diff(a, b, fromfile=f"a/{path}", tofile=f"b/{path}"))

def apply_patch(root: Path, patch: Patch) -> None:
    fp = root / patch.path
    if not fp.exists():
        raise FileNotFoundError(patch.path)
    current = fp.read_text(encoding="utf-8", errors="replace")
    if current != patch.before:
        raise RuntimeError(
            f"File changed since analysis: {patch.path}\n"
            f"Refusing to apply (safety). Re-run analyze."
        )
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = fp.with_suffix(fp.suffix + f".bak_{ts}")
    backup.write_text(current, encoding="utf-8")
    fp.write_text(patch.after, encoding="utf-8")
PY

cat > dev_agent/llm.py <<'PY'
from __future__ import annotations

import os
from openai import OpenAI

def get_client() -> OpenAI:
    key = os.environ.get("OPENAI_API_KEY", "")
    if not key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    return OpenAI(api_key=key)
PY

cat > dev_agent/architect.py <<'PY'
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from dev_agent.llm import get_client
from dev_agent.scanner import FileDoc

SYSTEM = """You are a principal software architect and FastAPI expert.
You analyze codebases and propose safe, incremental improvements.
You MUST:
- be concrete and reference actual modules/files
- propose changes as small, reviewable steps
- never assume unshown files exist
- avoid breaking public APIs unless necessary; if so, call it out
"""

@dataclass
class Proposal:
    title: str
    priority: str  # HIGH/MED/LOW
    rationale: str
    changes: list[dict]  # each {path, action, description}

def _chunk_docs(docs: list[FileDoc], max_files: int = 8) -> list[list[FileDoc]]:
    return [docs[i:i+max_files] for i in range(0, len(docs), max_files)]

def analyze_layers(project_root: Path, docs: list[FileDoc]) -> str:
    """Returns markdown notes about layers/gaps."""
    client = get_client()
    notes = []

    chunks = _chunk_docs(docs, max_files=10)
    for idx, ch in enumerate(chunks, 1):
        payload = "\n\n".join([f"===== FILE: {d.path} =====\n{d.text}" for d in ch])
        prompt = f"""Analyze this subset of a FastAPI project (chunk {idx}/{len(chunks)}).
Return Markdown notes:
- What components are present
- Architecture patterns used
- Risks/smells
- Missing parts
- Security concerns
Keep it concrete.
"""
        r = client.chat.completions.create(
            model="gpt-4.1-mini",
            messages=[{"role":"system","content":SYSTEM},{"role":"user","content":prompt},{"role":"user","content":payload}],
            temperature=0.2,
        )
        notes.append(r.choices[0].message.content)

    merged = "\n\n---\n\n".join(notes)

    final_prompt = """Using the merged notes, produce:
1) Architecture map (layers + flows)
2) Top gaps (prioritized)
3) Risks register (HIGH/MED/LOW)
4) Recommended roadmap (3 phases)
Return Markdown.
"""
    r2 = client.chat.completions.create(
        model="gpt-4.1",
        messages=[{"role":"system","content":SYSTEM},{"role":"user","content":final_prompt},{"role":"user","content":merged}],
        temperature=0.2,
    )
    return r2.choices[0].message.content

def propose_improvements(analysis_md: str) -> list[Proposal]:
    client = get_client()
    prompt = """From the analysis, produce 8-15 improvement proposals as JSON array.
Each proposal:
{
  "title": "...",
  "priority": "HIGH|MED|LOW",
  "rationale": "...",
  "changes": [
     {"path":"app/..", "action":"edit|add|delete", "description":"..."}
  ]
}
Rules:
- Keep edits minimal and safe.
- Prefer adding missing observability, security hardening, config hygiene, typing, tests.
- Refer to existing files by correct paths.
- Output valid JSON only.
"""
    r = client.chat.completions.create(
        model="gpt-4.1",
        messages=[{"role":"system","content":SYSTEM},{"role":"user","content":prompt},{"role":"user","content":analysis_md}],
        temperature=0.2,
    )
    raw = r.choices[0].message.content.strip()
    data = json.loads(raw)
    return [Proposal(**p) for p in data]
PY

cat > dev_agent/editor.py <<'PY'
from __future__ import annotations

import json
from pathlib import Path
from dev_agent.llm import get_client
from dev_agent.patcher import Patch

SYSTEM = """You are a senior Python engineer.
You must return ONLY JSON with keys: path, before, after, rationale.
- 'before' must match the exact file content provided.
- 'after' is the full new file content.
- Edits must be minimal, safe, and keep formatting consistent.
- Do not remove functionality unless requested.
"""

def generate_patch(root: Path, path: str, instruction: str) -> Patch:
    fp = root / path
    if not fp.exists():
        raise FileNotFoundError(path)
    before = fp.read_text(encoding="utf-8", errors="replace")

    client = get_client()
    prompt = f"""Modify the file according to instruction.

Instruction:
{instruction}

Return JSON only:
{{
  "path": "{path}",
  "before": "<exact original file>",
  "after": "<full modified file>",
  "rationale": "<why>"
}}
"""
    r = client.chat.completions.create(
        model="gpt-4.1",
        messages=[
            {"role":"system","content":SYSTEM},
            {"role":"user","content":prompt},
            {"role":"user","content":f"===== FILE: {path} =====\n{before}"},
        ],
        temperature=0.1,
    )

    data = json.loads(r.choices[0].message.content)
    return Patch(path=data["path"], before=data["before"], after=data["after"], rationale=data.get("rationale",""))
PY

cat > dev_agent/cli.py <<'PY'
from __future__ import annotations

import json
from pathlib import Path

from rich.console import Console
from rich.table import Table
from rich.prompt import Prompt, Confirm

from dev_agent.scanner import list_files, read_files
from dev_agent.architect import analyze_layers, propose_improvements, Proposal
from dev_agent.editor import generate_patch
from dev_agent.patcher import unified_diff, apply_patch, Patch

console = Console()
ROOT = Path(".").resolve()
STATE_DIR = ROOT / ".agent_tmp"
STATE_DIR.mkdir(exist_ok=True)

ANALYSIS_PATH = STATE_DIR / "analysis.md"
PROPOSALS_PATH = STATE_DIR / "proposals.json"

def cmd_analyze() -> None:
    files = list_files(ROOT)
    docs = read_files(ROOT, files)
    console.print(f"🔎 Reading {len(docs)} files...")
    md = analyze_layers(ROOT, docs)
    ANALYSIS_PATH.write_text(md, encoding="utf-8")
    console.print(f"✅ Analysis saved: {ANALYSIS_PATH}")
    console.print("Tip: run [bold]propose[/bold] next.")

def cmd_show_analysis() -> None:
    if not ANALYSIS_PATH.exists():
        console.print("❌ No analysis yet. Run: analyze")
        return
    console.print(ANALYSIS_PATH.read_text(encoding="utf-8", errors="replace"))

def cmd_propose() -> None:
    if not ANALYSIS_PATH.exists():
        console.print("❌ No analysis yet. Run: analyze")
        return
    proposals = propose_improvements(ANALYSIS_PATH.read_text(encoding="utf-8", errors="replace"))
    PROPOSALS_PATH.write_text(json.dumps([p.__dict__ for p in proposals], ensure_ascii=False, indent=2), encoding="utf-8")
    console.print(f"✅ Proposals saved: {PROPOSALS_PATH}")
    cmd_list()

def _load_proposals() -> list[Proposal]:
    if not PROPOSALS_PATH.exists():
        return []
    data = json.loads(PROPOSALS_PATH.read_text(encoding="utf-8"))
    return [Proposal(**p) for p in data]

def cmd_list() -> None:
    proposals = _load_proposals()
    if not proposals:
        console.print("❌ No proposals yet. Run: propose")
        return
    t = Table(title="Sovereign Dev Agent — Proposals")
    t.add_column("#", justify="right")
    t.add_column("Priority")
    t.add_column("Title")
    t.add_column("Files/Actions")
    for i, p in enumerate(proposals, 1):
        files = ", ".join([f'{c["action"]}:{c["path"]}' for c in p.changes[:3]])
        if len(p.changes) > 3:
            files += f" (+{len(p.changes)-3})"
        t.add_row(str(i), p.priority, p.title, files)
    console.print(t)

def cmd_detail(n: int) -> None:
    proposals = _load_proposals()
    if n < 1 or n > len(proposals):
        console.print("❌ Invalid proposal number")
        return
    p = proposals[n-1]
    console.print(f"[bold]{p.title}[/bold]  ({p.priority})")
    console.print(p.rationale)
    console.print("\n[bold]Planned changes:[/bold]")
    for c in p.changes:
        console.print(f" - {c['action']} {c['path']}: {c['description']}")

def cmd_apply(n: int) -> None:
    proposals = _load_proposals()
    if n < 1 or n > len(proposals):
        console.print("❌ Invalid proposal number")
        return

    p = proposals[n-1]
    console.print(f"🧩 Applying proposal: [bold]{p.title}[/bold] ({p.priority})")

    # We only auto-generate patches for "edit" actions.
    # "add/delete" are shown but not executed automatically (safety).
    for c in p.changes:
        action = c.get("action")
        path = c.get("path")
        desc = c.get("description","")
        if action != "edit":
            console.print(f"⚠️ Skipping non-edit action for safety: {action} {path}")
            continue

        instruction = f"""Implement this change in {path}:

{desc}

Constraints:
- keep existing behavior unless explicitly required
- do minimal diff
- preserve formatting and imports
- if adding security features (CORS/rate limit), do it correctly for FastAPI
"""
        patch: Patch = generate_patch(ROOT, path, instruction)
        diff = unified_diff(path, patch.before, patch.after)

        console.print(f"\n[bold]Diff for {path}[/bold]\n")
        console.print(diff if diff.strip() else "(no diff)")

        if not diff.strip():
            continue

        if Confirm.ask(f"Apply changes to {path}?", default=False):
            apply_patch(ROOT, patch)
            console.print(f"✅ Applied with backup (.bak_*) : {path}")
        else:
            console.print("⏭️ Skipped.")

    console.print("\n✅ Done. Re-run tests if needed.")

def repl() -> None:
    console.print("[bold]Sovereign Dev Agent[/bold] — commands: analyze, show, propose, list, detail N, apply N, exit")
    while True:
        cmd = Prompt.ask("agent>").strip()
        if cmd in ("exit", "quit"):
            return
        if cmd == "analyze":
            cmd_analyze()
        elif cmd == "show":
            cmd_show_analysis()
        elif cmd == "propose":
            cmd_propose()
        elif cmd == "list":
            cmd_list()
        elif cmd.startswith("detail "):
            n = int(cmd.split(maxsplit=1)[1])
            cmd_detail(n)
        elif cmd.startswith("apply "):
            n = int(cmd.split(maxsplit=1)[1])
            cmd_apply(n)
        else:
            console.print("Unknown command.")

if __name__ == "__main__":
    repl()
PY

echo "✅ Installing entrypoint script..."
cat > agent.sh <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd /data/data/com.termux/files/home/sovereign_core
# shellcheck disable=SC1091
source .venv/bin/activate
python -m dev_agent.cli
BASH
chmod +x agent.sh

echo
echo "🎉 Dev Agent installed."
echo "Next:"
echo "  export OPENAI_API_KEY=...   (if not already)"
echo "  ./agent.sh"
