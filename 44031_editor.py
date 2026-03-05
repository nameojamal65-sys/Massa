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
