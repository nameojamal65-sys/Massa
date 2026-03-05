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
