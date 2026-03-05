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
