#!/usr/local/bin/python
import pathlib
import sys
import subprocess

p = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "8080")

sys.exit(subprocess.call(["node", p.name], cwd=p.parent))
