#!/usr/bin/env python3
import os, shutil
from pathlib import Path

ROOT = Path(os.getcwd())
for f in ROOT.iterdir():
    if f.is_file():
        ext = f.suffix.lower()[1:] or "others"
        target = ROOT / ext
        target.mkdir(exist_ok=True)
        shutil.move(str(f), str(target))
print("✅ Files organized by extension")
