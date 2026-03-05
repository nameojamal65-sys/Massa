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
