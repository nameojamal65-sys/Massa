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
