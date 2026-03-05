import os, sys
import pytest
from pathlib import Path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

@pytest.fixture(autouse=True)
def env(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("INVENTORY_DB", str(tmp_path / "test.db"))
    monkeypatch.setenv("INVENTORY_API_KEY", "test-key")
    monkeypatch.setenv("INVENTORY_RL_PER_MIN", "9999")
    monkeypatch.setenv("INVENTORY_LOG", str(tmp_path / "test.log"))
    yield
